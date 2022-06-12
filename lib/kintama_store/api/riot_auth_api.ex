defmodule KintamaStoreBot.Api.RiotAuthApi do
  alias KintamaStoreBot.Utils.ApiUtils

  @spec auth_cookies(Tesla.Client.t()) :: String.t()
  @doc """
  Establish session and get cookie
  セッションを確立して、そのクッキーを得る
  """
  def auth_cookies(client) do
    req_body = %{
      client_id: "play-valorant-web-prod",
      nonce: 1,
      redirect_uri: "https://playvalorant.com/opt_in",
      response_type: "token id_token",
    }

    {:ok, response} = Tesla.post(client, "/api/v1/authorization", req_body)

    Tesla.get_headers(response, "set-cookie")
    |> Enum.join(";") # Join the cookies and then return full cookie string
  end

  @doc """
  To use to login user
  ログインするときに使う
  """
  def auth_request(client, cookie, username, password) do
    req_body = %{
      type: "auth",
      username: username,
      password: password,
      remember: true,
      language: "ja_JP", # This should be able to change through config
    }

    {:ok, response} = Tesla.put(client, "/api/v1/authorization", req_body, headers: [{"cookie", cookie}])
    cookie = Tesla.get_headers(response, "set-cookie") |> Enum.join(";")

    %{
      body: response.body,
      cookie: cookie
    }
  end

  @doc """
  To authorize 2FA account information
  2FAを認証するときに使う
  """
  @spec send_2fa_code(Tesla.Client.t(), String.t(), String.t()) :: Tesla.Env.body()
  def send_2fa_code(client, cookie, code) do
    req_body = %{
      type: "multifactor",
      code: code,
      rememberDevice: false
    }

    Tesla.put(client, "/api/v1/authorization", req_body, headers: [{"cookie", cookie}])
    |> ApiUtils.return_success_response()
  end

  @doc """
  To re-authenticate cookie, and you don't need token or something else
  Cookieを再認証するときに使う、トークンなどのものは必要ない
  """
  def reauth_cookie(client) do
    Tesla.get(client, "/authorize?redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&client_id=play-valorant-web-prod&response_type=token%20id_token&nonce=1")
    |> ApiUtils.return_success_response()
  end

  @doc """
  Get current player's uuid
  現在ログインしているプレイヤーのuuidを取得する
  """
  @spec get_uuid(Tesla.Client.t()) :: String.t()
  def get_uuid(client) do
    {:ok, response} = Tesla.get(client, "/userinfo")

    # IO.inspect(response)

    response.body["sub"]
  end

  @spec client(String.t()) :: Tesla.Client.t()
  def client(riot_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://auth.riotgames.com"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BearerAuth, token: riot_token},
      {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}, {"user-agent", "RiotClient/51.0.0.4429735.4381201 rso-auth (Windows;10;;Professional, x64)"}, {"X-Curl-Source", "Api"}]}
    ]

    Tesla.client(middleware)
  end
end
