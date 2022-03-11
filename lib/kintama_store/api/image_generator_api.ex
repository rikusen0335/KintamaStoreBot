defmodule KintamaStoreBot.Api.ImageGeneratorApi do
  alias KintamaStoreBot.Struct.ImageGenerator.SkinInfo

  @spec generate_daily_store(Tesla.Client.t(), list(%SkinInfo{})) :: Tesla.Env.result()
  def generate_daily_store(client, data) do
    Tesla.post(client, "/generate", %{weaponSkins: data})
  end

  @spec client() :: Tesla.Client.t()
  def client() do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://valorant-store-bot-image-generator.vercel.app"},
      Tesla.Middleware.EncodeJson,
      {Tesla.Middleware.Timeout, timeout: 10_000},
      # {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]}
    ]

    Tesla.client(middleware)
  end
end
