defmodule RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Kvstore.Router, as: Router

  # @tag :skip
  @doc """
  Проверяем существующий роутинг на все методы
  """
  test "test malformed key" do
    conn =
      conn(:post, "http://localhost:4040/create?value=val1&ttl=6")
      |> Router.call([])

    assert conn.status == 200
  end

  # @tag :skip
  test "test exists method" do
    conn =
      conn(:post, "http://localhost:4040/create?key=key1&value=val1&ttl=6")
      |> Router.call([])

    assert conn.status == 200

    conn =
      conn(:get, "http://localhost:4040/read?key=key1")
      |> Router.call([])

    assert conn.status == 200

    conn =
      conn(:put, "http://localhost:4040/update?key=key1&value=val1&ttl=8")
      |> Router.call([])

    assert conn.status == 200

    conn =
      conn(:delete, "http://localhost:4040/delete?key=key1")
      |> Router.call([])

    assert conn.status == 200
  end

  # @tag :skip
  @doc """
  Проверяем несуществующий роутинг на все методы
  """
  test "test not exists method" do
    conn =
      conn(:post, "http://localhost:4040/saddfsdgdsfgsd")
      |> Router.call([])

    assert conn.status == 404

    conn =
      conn(:get, "http://localhost:4040/saddfsdgdsfgsd")
      |> Router.call([])

    assert conn.status == 404

    conn =
      conn(:put, "http://localhost:4040/saddfsdgdsfgsd")
      |> Router.call([])

    assert conn.status == 404

    conn =
      conn(:delete, "http://localhost:4040/saddfsdgdsfgsd")
      |> Router.call([])

    assert conn.status == 404
  end

  @doc """
  Тестируем черный ящик
  """
  test "black box" do
    # Создаем-читаем
    conn =
      conn(:post, "http://localhost:4040/create?key=key1&value=val1&ttl=6")
      |> Router.call([])

    assert conn.status == 200

    conn =
      conn(:get, "http://localhost:4040/read?key=key1")
      |> Router.call([])

    assert conn.status == 200
    assert conn.resp_body == "\"val1\""
    # Обновляем-читаем
    conn =
      conn(:put, "http://localhost:4040/update?key=key1&value=valch&ttl=8")
      |> Router.call([])

    assert conn.status == 200

    conn =
      conn(:get, "http://localhost:4040/read?key=key1")
      |> Router.call([])

    assert conn.status == 200
    assert conn.resp_body == "\"valch\""
    # Удаляем-читаем
    conn =
      conn(:delete, "http://localhost:4040/delete?key=key1")
      |> Router.call([])

    assert conn.status == 200

    conn =
      conn(:get, "http://localhost:4040/read?key=key1")
      |> Router.call([])

    assert conn.status == 200
    assert conn.resp_body == "ERROR"
    # Создаем-читаем с истекшим ттл
    conn =
      conn(:post, "http://localhost:4040/create?key=key1&value=val1&ttl=1")
      |> Router.call([])

    assert conn.status == 200

    Process.sleep(1000)

    conn =
      conn(:get, "http://localhost:4040/read?key=key1")
      |> Router.call([])

    assert conn.status == 200
    assert conn.resp_body == "ERROR"
  end
end
