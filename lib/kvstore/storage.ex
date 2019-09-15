defmodule Kvstore.Storage do
  @moduledoc """
  Функции для работы с KV хранилищем.
  Не грузим фрондендщиков и возвращаем только false или true, то есть получилось или нет.
  При чтении обновлении и вставке учитываем TTL
  """
  require Logger
  require Kvstore
  use GenServer

  @dets_store_table :dets_store_table
  @ets_sort_table :ets_sort_table
  @ets_tmp_table :ets_tmp_table

  # Создает KV элимент
  # Если элемент новый или ttl уже истек возвращаем true иначе false
  @spec kv_create(binary(), binary(), integer()) :: true | false
  defp kv_create(key, value, ttl) do
    delete_expire_ttl()
    expire = :os.system_time(:seconds) + ttl

    if :dets.insert_new(@dets_store_table, {key, value, expire}) do
      unless :ets.insert_new(@ets_sort_table, {expire, [key]}) do
        [{_, v_ets}] = :ets.lookup(@ets_sort_table, expire)
        :ets.insert(@ets_sort_table, {expire, v_ets ++ [key]})
      end

      true
    else
      false
    end
  end

  defp insert_expire_ets(expire, key) do
    case :ets.lookup(@ets_sort_table, expire) do
      # Если данные с указанной датой существуют в ets то добавляем текущий ключ
      [{_, v_ets}] -> :ets.insert(@ets_sort_table, {expire, v_ets ++ [key]})
      # Если данных с новой датой не содержалось в таблице пишем новые данные
      [] -> :ets.insert(@ets_sort_table, {expire, [key]})
    end
  end

  # Обновляем KV элемент при обновлении учитываем истекший TTL
  # Если элемент существует и ttl не истек, то обновляем и возвращаем true иначе false
  @spec kv_update(binary(), binary(), integer()) :: true | false
  defp kv_update(key, value, ttl) do
    delete_expire_ttl()
    expire = :os.system_time(:seconds) + ttl

    case :dets.lookup(@dets_store_table, key) do
      [{key, _, old_expire}] ->
        [{_, v_ets}] = :ets.lookup(@ets_sort_table, old_expire)

        # Если ключ в ets один то просто изменяем ttl dets удаляем старый и создаем новый элемен в ets
        if length(v_ets) == 1 do
          :dets.insert(@dets_store_table, {key, value, expire})
          :ets.delete(@ets_sort_table, old_expire)
          insert_expire_ets(expire, key)
          true
          # Если ключ в ets один
        else
          # В dets  изменяем существующий ключ
          :dets.insert(@dets_store_table, {key, value, expire})
          # Удаляем из списка v_ets текущий ключ
          new_v_ets = List.delete(v_ets, key)

          # И записываем назад оставшиеся дынные без текущего ключа
          :ets.insert(@ets_sort_table, {old_expire, new_v_ets})
          insert_expire_ets(expire, key)

          true
        end

      _ ->
        false
    end
  end

  # Читаем KV элемент при этом учитываем истекший TTL
  # Если элемент существует и ttl не истек возвращаем true иначе false
  @spec kv_read(binary()) :: false | String
  defp kv_read(key) do
    delete_expire_ttl()
    res = :dets.lookup(@dets_store_table, key)

    case res do
      [{_, v, _}] -> inspect(v)
      _ -> false
    end
  end

  # Удаляем
  @spec kv_delete(binary) :: false | true
  defp kv_delete(key) do
    delete_expire_ttl()

    case :dets.lookup(@dets_store_table, key) do
      [{_, _, old_ttl}] ->
        # Ключ есть и мы его удаляем
        :dets.delete(@dets_store_table, key)
        [{_, v_ets}] = :ets.lookup(@ets_sort_table, old_ttl)

        if length(v_ets) == 1 do
          :ets.delete(@ets_sort_table, old_ttl)
        else
          new_v_ets = List.delete(v_ets, key)
          :ets.insert(@ets_sort_table, {old_ttl, new_v_ets})
        end

        true

      _ ->
        false
    end
  end

  defp loop_delete(:"$end_of_table"), do: :ok

  defp loop_delete(key) do
    # Проходим по сортированной таблице
    [{ttl, v_ets}] = :ets.lookup(@ets_sort_table, key)
    # Получаем следующий ключ для итерации
    key = :ets.next(@ets_sort_table, key)

    # Если ttl больше системного то прерываем цикл, так как остальные ttl все старше (таблица отсортирована)
    # Иначе удаляем запись как в dets так и в ets
    if ttl > :os.system_time(:seconds) do
      loop_delete(:"$end_of_table")
    else
      :ets.delete(@ets_sort_table, ttl)

      # В ets ключи из dets хранятся в виде списка проходим по каждому ключу
      Enum.map(v_ets, fn k -> :dets.delete(@dets_store_table, k) end)
      loop_delete(key)
    end
  end

  @doc """
  Удаляем элемент с истекшим ttl
  """
  @spec delete_expire_ttl() :: :ok
  def delete_expire_ttl() do
    # Передаем первый ключ отсортированной таблицы
    loop_delete(:ets.first(@ets_sort_table))
  end

  defp loop(:"$end_of_table", _, _), do: :ok

  defp loop(key, table_from, table_to) do
    [{k_f, _, t_f}] = :ets.lookup(table_from, key)

    # Сначала пытаемся вставить как новый элемент, в этом случае наличие будет проверено встроенными средствами ВМ
    unless :ets.insert_new(table_to, {t_f, [k_f]}) do
      [{_, v_t}] = :ets.lookup(table_to, t_f)
      :ets.insert(table_to, {t_f, [k_f] ++ v_t})
    end

    key = :ets.next(table_from, key)
    loop(key, table_from, table_to)
  end

  @doc """
  Функция обратного вызова для GenServer.init/1
  """
  @impl true
  def init(state) do
    # Process.flag(:trap_exit, true)
    :dets.open_file(@dets_store_table, type: :set) |> IO.inspect()
    :ets.new(@ets_tmp_table, [:set, :public, :named_table]) |> IO.inspect()
    :ets.new(@ets_sort_table, [:ordered_set, :public, :named_table]) |> IO.inspect()
    # Составляем ets sort
    case :dets.to_ets(@dets_store_table, @ets_tmp_table) do
      @ets_tmp_table ->
        key = :ets.first(@ets_tmp_table)

        case loop(key, @ets_tmp_table, @ets_sort_table) do
          :ok ->
            Logger.info("Fill sorting table ok")
            :ets.delete_all_objects(@ets_tmp_table)
            {:ok, state}

          _ ->
            Logger.error("Fill sorting table error!")
            :error
        end

      _ ->
        Logger.error("Convert dets to ets error!")
        :error
    end
  end

  @doc """
  Колбэки для генсервера реализующие crud
  """
  @impl true
  def handle_call({:create, key, val, ttl}, _from, state) do
    value = kv_create(key, val, ttl)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:update, key, val, ttl}, _from, state) do
    value = kv_update(key, val, ttl)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:read, key}, _from, state) do
    value = kv_read(key)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    value = kv_delete(key)
    {:reply, value, state}
  end

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Функции для маскировки отсылки собщений
  """
  def read(key), do: GenServer.call(__MODULE__, {:read, key})
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})
  def create(key, value, int_ttl), do: GenServer.call(__MODULE__, {:create, key, value, int_ttl})
  def update(key, value, int_ttl), do: GenServer.call(__MODULE__, {:update, key, value, int_ttl})

  # Пытался сделать вежливое завершение работает если непосредственно послать kill процессу
  # Когда ВМ крэшится этот колбэк не вызывается
  @impl true
  def terminate(reason, state) do
    :dets.close(@dets_store_table)
    IO.inspect("#{reason} #{state}")
    state
  end
end
