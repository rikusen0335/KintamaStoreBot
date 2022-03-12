defmodule KintamaStoreBot.Consumer do
  alias Nostrum.Api

  alias KintamaStoreBot.Struct.State.AuthState
  alias KintamaStoreBot.Handler.{InteractionHandler}

  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nosedrum.Storage.ETS, as: CommandStorage

  use Nostrum.Consumer

  @commands %{
    "applycmd" => KintamaStoreBot.Cogs.ApplyCommand,
    "removecmd" => KintamaStoreBot.Cogs.RemoveCommand,
    "listcmd" => KintamaStoreBot.Cogs.ListGuildCommands,
    # "help" => KintamaStoreBot.Cogs.Help,
  }

  def start_link do
    Memento.Schema.create([node()])
    Memento.start

    Memento.Schema.set_storage_type(node(), :ram_copies)
    Memento.Table.create!(AuthState)

    Consumer.start_link(__MODULE__)
  end

  def handle_event({:READY, _data, _ws_state}) do
    Api.update_status(:online, ".help")

    Enum.each(@commands, fn {name, cog} -> CommandStorage.add_command([name], cog) end)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    CommandInvoker.handle_message(msg, CommandStorage)
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    # IO.puts("Got a interaction")
    # IO.inspect(interaction)
    InteractionHandler.handle_before(interaction)
  end

  def handle_event(_data), do: :ok
end
