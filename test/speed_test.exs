defmodule SpeedTest do
  use ExUnit.Case, async: false

  defp loop(:"$end_of_table") do
    IO.puts("End")
  end

  defp loop(key) do
    [{k, _, t}] = :ets.lookup(:temp, key)
    :ets.insert(:sort, {t, k})
    key = :ets.next(:temp, key)
    loop(key)
  end

  defp loop2(:"$end_of_table") do
    IO.puts("End")
  end

  defp loop2(key) do
    [{k, _, t}] = :dets.lookup(:kvstorage2, key)
    :ets.insert(:sort, {t, k})
    key = :dets.next(:kvstorage2, key)
    loop2(key)
  end

  @tag :skip
  @doc "Тестирование скорости DETS"
  test "create speed dets" do
    {_, b_t, bm_t} = :os.timestamp()
    :dets.open_file(:kvstorage2, type: :set)

    # for f <- 1..100_000 do
    for f <- 1..10 do
      :dets.insert_new(
        :kvstorage2,
        {"key" <> Integer.to_string(f), Integer.to_string(f + 2), :os.system_time(:seconds) + f}
      )
    end

    {_, e_t, em_t} = :os.timestamp()

    IO.puts(" create dets sec: #{e_t - b_t} ms: #{em_t - bm_t} ")
  end

  @tag :skip
  # Поэлементное чтение 100 000 row из dets напрямую sec: 0 ms: 263081
  test "speed dets2ets" do
    {_, b_t, bm_t} = :os.timestamp()
    :dets.open_file(:kvstorage2, type: :set)
    :ets.new(:temp, [:set, :public, :named_table])
    :ets.new(:sort, [:ordered_set, :public, :named_table])
    :dets.to_ets(:kvstorage2, :temp)

    loop(:ets.first(:temp))
    {_, e_t, em_t} = :os.timestamp()
    IO.puts("speed dets2ets sec: #{e_t - b_t} ms: #{em_t - bm_t} ")
  end

  @tag :skip
  # Поэлементное чтение 100 000 row из dets напрямую sec: 3 ms: 366682
  test "speed read from dets2ets" do
    {_, b_t, bm_t} = :os.timestamp()
    :dets.open_file(:kvstorage2, type: :set)
    :ets.new(:sort, [:ordered_set, :public, :named_table])

    loop2(:dets.first(:kvstorage2))
    {_, e_t, em_t} = :os.timestamp()
    IO.puts("read from dets2ets sec: #{e_t - b_t} ms: #{em_t - bm_t} ")
  end
end
