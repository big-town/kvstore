defmodule ShowTest do
  @moduledoc """
  Это тесты для визуальной оценки
  """
  use ExUnit.Case, async: false
  require Kvstore

  @dets_store_table :dets_store_table
  @ets_sort_table :ets_sort_table
  @ets_tmp_table :ets_tmp_table

  @tag :skip
  test "Show all table " do
    IO.puts("**************CREATE********************")

    for f <- 1..20 do
      Kvstore.Storage.create("key" <> Integer.to_string(f), Integer.to_string(f + 10), f)
    end

    Kvstore.Utils.show_table(@dets_store_table, :dets)
    Kvstore.Utils.show_table(@ets_sort_table, :ets)
    # Kvstore.Utils.show_table(Kvstore.ets_tmp_table,:ets)
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    IO.puts("#{inspect(dets_i[:size])} == #{inspect(ets_i)}")
    # assert dets_i[:size] == ets_i[:size]
    IO.puts("**********************************")
    IO.inspect(:os.system_time(:seconds))

    IO.puts("**************DELETE********************")
    Process.sleep(3000)
    IO.inspect(:os.system_time(:seconds))

    Kvstore.Storage.delete_expire_ttl()

    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    IO.puts("#{inspect(dets_i[:size])} == #{inspect(ets_i)}")
    # assert dets_i[:size] == ets_i[:size]
    IO.puts("DETS")
    Kvstore.Utils.show_table(@dets_store_table, :dets)
    IO.puts("ETS")
    Kvstore.Utils.show_table(@ets_sort_table, :ets)
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    IO.puts("#{inspect(dets_i[:size])} == #{inspect(ets_i)}")

    # Kvstore.Utils.show_table(Kvstore.ets_tmp_table,:ets)
    IO.puts("**********************************")
  end

  @tag :skip
  test "Show all table after update " do
    IO.puts("*************UPDATE*********************")
    Kvstore.Storage.update("key10", "qwqwqwq", 5)

    IO.inspect(:os.system_time(:seconds))
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    IO.puts("#{inspect(dets_i[:size])} == #{inspect(ets_i)}")
    # assert dets_i[:size] == ets_i[:size]

    Kvstore.Utils.show_table(@dets_store_table, :dets)
    Kvstore.Utils.show_table(@ets_sort_table, :ets)
    # Kvstore.Utils.show_table(Kvstore.ets_tmp_table,:ets)
    IO.puts("**********************************")
    IO.puts(Kvstore.Storage.read("key10"))
    Kvstore.Storage.delete("key10")
    IO.puts("************AFTER DELETE10**********************")
    Kvstore.Utils.show_table(@dets_store_table, :dets)
    Kvstore.Utils.show_table(@ets_sort_table, :ets)
    dets_i = :dets.info(@dets_store_table)
    ets_i = Kvstore.Utils.count_keys(@ets_sort_table)
    IO.puts("#{inspect(dets_i[:size])} == #{inspect(ets_i)}")

    # Kvstore.Utils.show_table(Kvstore.ets_tmp_table,:ets)
  end
end
