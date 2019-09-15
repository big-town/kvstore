defmodule Kvstore.Utils do
  @moduledoc """
  Тулзы
  """
  require Kvstore

  defp loop_show(_, :"$end_of_table", _) do
    IO.puts("End")
  end

  defp loop_show(table, key, type) do
    IO.inspect(type.lookup(table, key))
    key = type.next(table, key)
    loop_show(table, key, type)
  end

  @doc """
  Просмотр таблиц

  ## Параметры
  - table: имя таблицы, например: `:table`
  - type: тип таблицы  `:dets`

  ## Пример
  ```
  iex> Kvstore.Utils.show_table(Kvstore.ets_tmp_table,:ets)
      :ok
  ```
  """
  # @spec show_table(atom(), atom()) :: none
  def show_table(table, type) do
    loop_show(table, type.first(table), type)
  end

  ############################################################
  defp loop_count_keys(_, key, sum \\ 0)

  defp loop_count_keys(_, :"$end_of_table", sum) do
    sum
  end

  defp loop_count_keys(table, key, sum) do
    [{_, v}] = :ets.lookup(table, key)

    key = :ets.next(table, key)
    # IO.inspect binding()
    loop_count_keys(table, key, sum + length(v))
  end

  @doc """
  Подсчет ключей в ets

  ## Параметры
  - table: имя таблицы, например: `:table`
  - key: тип таблицы  `:dets`

  ## Пример
  ```
  iex> Kvstore.Utils.show_table(Kvstore.ets_tmp_table,:ets)
      :ok
  ```
  """
  # @spec count_keys(atom()) :: integer
  def count_keys(table) do
    loop_count_keys(table, :ets.first(table))
  end
end
