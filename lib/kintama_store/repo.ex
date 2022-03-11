defmodule KintamaStoreBot.Repo do
  use Ecto.Repo,
    otp_app: :kintama_store_bot,
    adapter: Ecto.Adapters.SQLite3
end
