defmodule Test do
  alias KintamaStoreBot.Api.{RiotAuthApi,ValorantOfficialApi,ImageGeneratorApi}

  def hoge() do
    pem = File.read!("/etc/ssl/cert.pem")

    [priv_key | pub_key_certs] = :public_key.pem_decode(pem)
    # IO.inspect(priv_key)
    {:Certificate, <<_::binary>> = der_pkey, :not_encrypted} = priv_key

    der_certs = Enum.map(pub_key_certs, fn {_type, der, :not_encrypted} -> der end)

    # ssl_opts = [key: {:Certificate, der_pkey}, cert: der_certs]

    url = "https://auth.riotgames.com/api/v1/authorization"
    headers = [{"content-type", "application/json"}, {"user-agent", "RiotClient/51.0.0.4429735.4381201 rso-auth (Windows;10;;Professional, x64)"}, {"X-Curl-Source", "Api"}]
    supported = Enum.map(['TLS_AES_256_GCM_SHA384'], &:ssl.str_to_suite/1)
    check_hostname_opts = :hackney_ssl.check_hostname_opts('auth.riotgames.com')
    ssl_opts = Keyword.merge(check_hostname_opts, ciphers: supported)
    # ssl_opts =
    #   "auth.riotgames.com"
    #   |> to_charlist()
    #   |> :hackney_ssl.check_hostname_opts()
      # |> Keyword.put(:log_level, :debug)
      # |> Keyword.put(:versions, [:'tlsv1.3'])
    # ssl_opts = [{:versions, [:'tlsv1.3']}]

    # options = [
    #   ssl: ssl_opts,
    # ]

    body = Poison.encode!(%{
      client_id: "play-valorant-web-prod",
      nonce: "1",
      redirect_uri: "https://playvalorant.com/opt_in",
      response_type: "token id_token",
    })

    HTTPoison.post!(url, body, headers)
  end

  def httpc do
    body = Poison.encode!(%{
      client_id: "play-valorant-web-prod",
      nonce: "1",
      redirect_uri: "https://playvalorant.com/opt_in",
      response_type: "token id_token"
    })

    :httpc.request(:post, {'https://auth.riotgames.com/api/v1/authorization', [], 'application/json', body}, [], [])
  end

  def mint do
    host = "auth.riotgames.com"
    target_path = "/api/v1/authorization"
    headers = [{"Content-Type", "application/json; charset=utf-8"}]

    body = Poison.encode!(%{
      client_id: "play-valorant-web-prod",
      nonce: "1",
      redirect_uri: "https://playvalorant.com/opt_in",
      response_type: "token id_token"
    })

    {:ok, conn} = Mint.HTTP.connect(:https, host, 443)
    {:ok, conn, request_ref} = Mint.HTTP.request(conn, "POST", target_path, headers, body)

    receive do
      message ->
        wtf = Mint.HTTP.stream(conn, message)
        IO.inspect wtf
    end
  end

  def finch do
    url = "https://auth.riotgames.com/api/v1/authorization"
    headers = [{"Content-Type", "application/json"}]
    body = Poison.encode!(%{
      client_id: "play-valorant-web-prod",
      nonce: "1",
      redirect_uri: "https://playvalorant.com/opt_in",
      response_type: "token id_token"
    })

    IO.inspect(body)

    opts = [
      {:protocol, :http2}
    ]

    Finch.build(:post, url, headers, body, opts) |> Finch.request(MyFinch) |> IO.inspect()
  end

  def tesla() do
    req_body = %{
      client_id: "play-valorant-web-prod",
      nonce: 1,
      redirect_uri: "https://playvalorant.com/opt_in",
      response_type: "token id_token",
    }

    {:ok, response} = RiotAuthApi.client("") |> Tesla.post("/api/v1/authorization", req_body)
    response
  end

  def tls_start() do
    :ssl.start()
    :ssl.listen(8080, [{:certfile, "server.crt"}, {:keyfile, "server.key"}, {:cacertfile, "ca.crt"}, {:reuseaddr, true}, {:versions, [:'tlsv1.3']}])
    |> case do
      {:ok, listen_socket} ->
        {:ok, tls_socket} = :ssl.transport_accept(listen_socket)
        {:ok, socket} = :ssl.handshake(tls_socket)
        {:ok, socket}
      {:error, err} ->
        IO.inspect(err)
    end
  end
end
