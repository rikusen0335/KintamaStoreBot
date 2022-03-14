defmodule KintamaStoreBot.Worker do
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
    }
  end

  def start_link(word: word) do
    GenServer.start_link(__MODULE__)
  end

  def init(word) do
    KintamaStoreBot.Consumer.start_link()
    IO.puts("Started worker")
    {:ok}
  end
end
