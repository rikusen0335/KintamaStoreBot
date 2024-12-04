defmodule KintamaStoreBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :kintama_store_bot,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate",],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KintamaStoreBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.10"},
      # {:nostrum, github: "Kraigie/nostrum", override: true},
      # {:nostrum, path: "../nostrum", override: true},

      #{:nosedrum, "~> 0.6"},
      {:tesla, "~> 1.13"},

      # optional, but recommended adapter
      #{:hackney, "~> 1.20"},

      {:httpoison, "~> 2.2"},

      # optional, required by JSON middleware
      {:jason, ">= 1.4.4"},
      {:poison, "~> 6.0"},

      {:ecto, "~> 3.12"},
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.17.4"},

      {:tzdata, "~> 1.1.2"},

      {:memento, "~> 0.4.1"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
