defmodule KintamaStoreBot.Repo do
  use Ecto.Repo,
    otp_app: :kintama_store,
    adapter: Ecto.Adapters.Postgres
end
