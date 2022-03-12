defmodule KintamaStoreBot.Cogs.RemoveCommand do
  @behaviour Nosedrum.Command

  alias Nostrum.Api

  @impl true
  def usage, do: ["removecmd"]

  @impl true
  def description, do: "サーバーにあるアプリケーションコマンドのリストを表示する（ログに）"

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    {:ok, guild_commands} = Api.get_guild_application_commands(msg.guild_id)
    Enum.each(guild_commands, fn cmd -> Api.delete_guild_application_command(msg.guild_id, cmd.id) end)

    {:ok, global_commands} = Api.get_global_application_commands()
    Enum.each(global_commands, fn cmd -> Api.delete_global_application_command(cmd.id) end)

    Api.create_message(msg.channel_id, "すべてのコマンドが正常に削除されました")
  end
end
