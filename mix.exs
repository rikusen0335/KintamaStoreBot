defmodule KintamaStoreBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :kintama_store_bot,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      {:nostrum, "~> 0.6"},
      # {:nostrum, github: "Kraigie/nostrum", override: true},
      # {:nostrum, path: "../nostrum", override: true},

      {:nosedrum, "~> 0.4"},
      {:tesla, "~> 1.4"},

      # optional, but recommended adapter
      {:hackney, "~> 1.18"},

      {:httpoison, "~> 1.8"},

      # optional, required by JSON middleware
      {:jason, ">= 1.0.0"},
      {:poison, "~> 5.0"},

      {:ecto, "~> 3.7"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_sqlite3, "~> 0.7.3"},

      {:tzdata, "~> 1.1"},

      {:memento, "~> 0.3.2"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
