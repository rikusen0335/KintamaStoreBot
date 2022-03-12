defmodule KintamaStoreBot.Cogs.ApplyCommand do
  @behaviour Nosedrum.Command

  alias Nostrum.Api

  @impl true
  def usage, do: ["applycmd"]

  @impl true
  def description, do: "アプリケーションコマンドをサーバーに適用する"

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    login = %{
      name: "login",
      description: "Riotアカウントにログインします",
      options: [
        %{
          # ApplicationCommandType::STRING
          type: 3,
          name: "username",
          description: "RiotアカウントのID（Valorant#1234形式じゃないただのID）",
          required: true
        },
        %{
          # ApplicationCommandType::STRING
          type: 3,
          name: "password",
          description: "Riotアカウントのパスワード",
          required: true
        },
      ]
    }

    logout = %{
      name: "logout",
      description: "いまログインしているアカウントの情報を削除します",
    }

    store = %{
      name: "store",
      description: "いまログインしているアカウントの今日のストアを確認します",
    }

    Api.create_guild_application_command(msg.guild_id, login) |> IO.inspect()
    Api.create_guild_application_command(msg.guild_id, logout) |> IO.inspect()
    Api.create_guild_application_command(msg.guild_id, store) |> IO.inspect()

    Api.create_message(msg.channel_id, "すべてのコマンドが正常に適応されました")
  end
end
