defmodule KintamaStoreBot.Consumer do
  alias Nostrum.Api

  alias KintamaStoreBot.Struct.State.AuthState
  alias KintamaStoreBot.Struct.Ratelimit
  alias KintamaStoreBot.Handler.{InteractionHandler,MessageHandler}

  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nosedrum.Storage.ETS, as: CommandStorage

  use Nostrum.Consumer

  @commands %{
    "applycmd" => KintamaStoreBot.Cogs.ApplyCommand,
    "removecmd" => KintamaStoreBot.Cogs.RemoveCommand,
    "listcmd" => KintamaStoreBot.Cogs.ListGuildCommands,
    "help" => KintamaStoreBot.Cogs.Help,
  }

  def start_link do
    Memento.Schema.create([node()])
    Memento.start

    Memento.Schema.set_storage_type(node(), :ram_copies)
    Memento.Table.create!(AuthState)
    Memento.Table.create!(Ratelimit)

    Consumer.start_link(__MODULE__)
  end

  def handle_event({:READY, _data, _ws_state}) do
    Api.update_status(:online, ".help")

    Enum.each(@commands, fn {name, cog} -> CommandStorage.add_command([name], cog) end)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    try do
      CommandInvoker.handle_message(msg, CommandStorage)
      MessageHandler.handle_before(msg)
    rescue
      e ->
        Api.create_message(msg.channel_id, ":exclamation: コマンドの実行中にエラーが発生しました。もう一度お試しいただくか、管理者に連絡してください。")
        IO.inspect(e, label: "An error occued while handling message")
    end
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    try do
      # IO.puts("Got a interaction")
      # IO.inspect(interaction)
      InteractionHandler.handle_before(interaction)
    rescue
      e ->
        Api.create_interaction_response(interaction, %{
          type: 4,
          data: %{
            content: ":exclamation: コマンドの実行中にエラーが発生しました。もう一度お試しいただくか、管理者に連絡してください。",
            flags: 64
          }
        })
        IO.inspect(e, label: "An error occued while handling message")
    end
  end

  def handle_event({:GUILD_CREATE, guild, _ws_state}) do
    IO.puts("[ID: #{guild.id}] | [名前: #{guild.name}] のサーバーに加入しました。")

    initial_message = "こんにちは！\nまずは`/login`、他のサーバーですでにログイン済みの方は`/store`を使ってください！"

    case Api.create_message(guild.system_channel_id, initial_message) do
      {:ok, _} -> :noop
      error -> IO.inspect(error, label: "メッセージを送信できませんでした")
    end
  end

  def handle_event(_data), do: :ok
end
