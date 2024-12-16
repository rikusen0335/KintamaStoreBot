defmodule KintamaStoreBot.Plug.OAuthPlug do
  use Plug.Router

  def init(options) do
    # initialize options
    options
  end

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "hello world")
  end
  
  get "/callback" do
    IO.inspect(conn.query_params)
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "hello world")
  end

  match _ do
    send_resp(conn, 404, "404 Not Found")
  end
end
