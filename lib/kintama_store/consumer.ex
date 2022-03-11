defmodule KintamaStoreBot.Consumer do
  alias Nostrum.Api

  alias KintamaStoreBot.Struct.State.AuthState

  use Nostrum.Consumer

  @commands %{
    "applycmd" => ValorantStoreBot.Cogs.ApplyCommand,
    "help" => ValorantStoreBot.Cogs.Help,
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
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    # IO.puts("Got a interaction")
    # IO.inspect(interaction)
    Handler.Interaction.handle(interaction)
  end

  def handle_event(_data), do: :ok
end
