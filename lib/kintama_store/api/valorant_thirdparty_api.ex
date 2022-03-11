defmodule KintamaStoreBot.Api.ValorantThirdpartyApi do

  def get_weapon_skin_by_uuid(client, weapon_uuid) do
    Tesla.get(client, "/v1/weapons/skinlevels/" <> weapon_uuid <> "?language=ja-JP")
    |> case do
      {:error, _} -> "noop"
      {:ok, response} -> response.body
    end
  end

  def client do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://valorant-api.com"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]},
    ]

    Tesla.client(middleware)
  end
end
