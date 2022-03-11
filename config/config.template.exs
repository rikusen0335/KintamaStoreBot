import Config

config :nostrum,
  token: "YOUR BOT TOKEN"

# config :nosedrum,
#   prefix: System.get_env("BOT_PREFIX") || "."

config :tesla, adapter: Tesla.Adapter.Hackney

config :kintama_store_bot,
  ecto_repos: [KintamaStoreBot.Repo]

config :kintama_store_bot, KintamaStoreBot.Repo,
  database: "./database.db" # Change anything you want

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
