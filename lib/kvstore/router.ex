defmodule Kvstore.Router do
  @moduledoc """
  Реализуем CRUD API
  через методы POST, GET, PUT, DELETE
  create, read, update, delete
  """
  use Plug.Router
  use Plug.Debugger
  require Logger
  alias Plug.Conn.Query, as: Qw

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  post "/create" do
    qs = Qw.decode(conn.query_string)
    key = qs["key"]
    value = qs["value"]
    ttl = qs["ttl"]

    case Integer.parse(ttl) do
      {int_ttl, _} ->
        if Kvstore.Storage.create(key, value, int_ttl) && key != nil do
          send_resp(conn, 200, "OK")
        else
          send_resp(conn, 200, "ERROR")
        end

      :error ->
        send_resp(conn, 200, "ERROR TTL")
    end
  end

  put "/update" do
    qs = Qw.decode(conn.query_string)
    key = qs["key"]
    value = qs["value"]
    ttl = qs["ttl"]

    case Integer.parse(ttl) do
      {int_ttl, _} ->
        if Kvstore.Storage.update(key, value, int_ttl) && key != nil do
          send_resp(conn, 200, "OK")
        else
          send_resp(conn, 200, "ERROR")
        end

      :error ->
        send_resp(conn, 200, "ERROR TTL")
    end
  end

  get "/read" do
    qs = Qw.decode(conn.query_string)
    key = qs["key"]
    obj = Kvstore.Storage.read(key)

    if obj do
      send_resp(conn, 200, obj)
    else
      send_resp(conn, 200, "ERROR")
    end
  end

  delete "/delete" do
    qs = Qw.decode(conn.query_string)
    key = qs["key"]

    if Kvstore.Storage.delete(key) do
      send_resp(conn, 200, "OK")
    else
      send_resp(conn, 200, "ERROR")
    end
  end

  # Выдаем корневую страницу
  get "/" do
    send_file(conn, 200, "html/index.html")
  end

  # Сюда попадаем если нет соответствия API
  match _ do
    send_resp(conn, 404, "Entry API not found!")
  end
end
