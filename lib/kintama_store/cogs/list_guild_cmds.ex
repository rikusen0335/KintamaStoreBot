defmodule KintamaStoreBot.Cogs.ListGuildCommands do
  @behaviour Nosedrum.Command

  alias Nostrum.Api

  @impl true
  def usage, do: ["listcmd"]

  @impl true
  def description, do: "サーバーにあるアプリケーションコマンドのリストを表示する（ログに）"

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    {:ok, guild_commands} = Api.get_guild_application_commands(msg.guild_id)
    IO.inspect(guild_commands, label: "Guild commands")

    {:ok, global_commands} = Api.get_global_application_commands()
    IO.inspect(global_commands, label: "Global commands")

    Api.create_message(msg.channel_id, "ログに表示しています（管理者のみ確認可能）")
  end
end
