defmodule StoreageTest do
  use ExUnit.Case, async: false
  require Kvstore

  @dets_store_table :dets_store_table
  @ets_sort_table :ets_sort_table
  @ets_tmp_table :ets_tmp_table

  test "Storage test" do
    # Очищаем таблицы
    :ets.delete_all_objects(@ets_sort_table)
    :dets.delete_all_objects(@dets_store_table)

    # Заполняем таблицы
    for f <- 1..20 do
      Kvstore.Storage.create("key" <> Integer.to_string(f), Integer.to_string(f + 10), f)
    end

    # Попытаемся создать существующий элемент
    assert Kvstore.Storage.create("key20", 11111, 111) == false
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    old_count = ets_i

    # Таблицы всегда должны быть синхронизированы убедимся что количество ключей равно
    assert dets_i[:size] == ets_i
    # Количество записей должно быть равно 20
    assert 20 == ets_i

    # Ждем 4 сек
    Process.sleep(4000)
    Kvstore.Storage.delete_expire_ttl()
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)

    # Таблицы всегда должны быть синхронизированы убедимся что количество ключей равно
    assert dets_i[:size] == ets_i

    # После ожидания 4 сек количество элементов должно уменьшится на 4 по ттл
    assert old_count - 4 == ets_i

    # Этот ключ в любом случае успеем считать ттл 100
    Kvstore.Storage.update("key10", "aaaaaa", 100)
    assert Kvstore.Storage.read("key10") == "\"aaaaaa\""
    # Пишем ключ с ттл 0
    Kvstore.Storage.update("key20", "aaaaaa", 0)
    Process.sleep(1)
    # Этот ключ не успеем считать ттл 0 а пауза 1сек.
    assert Kvstore.Storage.read("key20") == false
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    old_count = ets_i

    # Таблицы всегда должны быть синхронизированы убедимся что количество ключей равно
    assert dets_i[:size] == ets_i

    # Удалим не существующий ключ
    assert Kvstore.Storage.delete("key20") == false
    # Удалим существующий ключ
    assert Kvstore.Storage.delete("key19") == true
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)

    # Таблицы всегда должны быть синхронизированы убедимся что количество ключей равно
    assert dets_i[:size] == ets_i

    # После этого количество записей должно уменьшится на 1
    assert old_count - 1 == ets_i
    # :dets.close(Kvstore.dets_store_table)
  end
end
