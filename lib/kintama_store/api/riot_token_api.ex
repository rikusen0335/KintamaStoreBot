defmodule KintamaStoreBot.Api.RiotTokenApi do
  def get_riot_entitlement_raw(client) do
    Tesla.post(client, "/api/token/v1", "")
  end

  @doc """
  Get token to use Valorant API
  Valorant APIで使うトークンを取得する
  """
  def get_riot_entitlement(client) do
    {:ok, response} = Tesla.post(client, "/api/token/v1", "")
    response.body["entitlements_token"]
  end

  def client(riot_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://entitlements.auth.riotgames.com"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BearerAuth, token: riot_token},
      {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]}
    ]

    Tesla.client(middleware)
  end
end
