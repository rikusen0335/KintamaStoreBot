defmodule KintamaStoreBot.Cogs.ApplyCommand do
  @behaviour Nosedrum.Command

  alias Nostrum.Api

  alias KintamaStoreBot.Utils.DiscordUtils

  @impl true
  def usage, do: ["applycmd"]

  @impl true
  def description, do: "アプリケーションコマンドをサーバーに適用する"

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    DiscordUtils.apply_guild_commands(msg.guild_id)

    Api.create_message(msg.channel_id, "すべてのコマンドが正常に適応されました")
  end
end
