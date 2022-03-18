defmodule KintamaStoreBot.Cogs.RemoveCommand do
  @behaviour Nosedrum.Command

  alias Nostrum.Api

  alias KintamaStoreBot.Utils.DiscordUtils

  @impl true
  def usage, do: ["removecmd"]

  @impl true
  def description, do: "サーバーにあるアプリケーションコマンドのリストを表示する（ログに）"

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    DiscordUtils.remove_guild_commands(msg.guild_id)

    Api.create_message(msg.channel_id, "すべてのコマンドが正常に削除されました")
  end
end
