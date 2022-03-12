defmodule KintamaStoreBot.Cogs.Help do
  @behaviour Nosedrum.Command

  alias Nostrum.Api

  import Nostrum.Struct.Embed

  @impl true
  def usage, do: ["help"]

  @impl true
  def description, do: "コマンドリストを表示"

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _) do
    embed = %Nostrum.Struct.Embed{}
    |> put_title("コマンドリスト")
    |> put_field("/login", "ログイン用のコマンド")
    |> put_field("/logout", "ログアウト用のコマンド")
    |> put_field("/store", "毎日更新されるストアを表示します。ログイン必須")
    |> put_field(".applycmd", "/loginが使えないときに試してください")

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end
end
