defmodule KintamaStoreBot.Handler.MessageHandler do
  alias Nostrum.Api
  alias Nostrum.Struct.{Message,User}

  def handle_before(msg) do
    if actionable_command?(msg) do
      msg
      |> handle()
    end
  end

  defp actionable_command?(msg) do
    if msg.author.bot == nil do
      true
    end
  end

  defp handle(%Message{content: content} = msg) do
    cond do
      String.contains?(content, "/login") ->
        Api.create_message(
          msg.channel_id,
          message_reference: %{message_id: msg.id},
          content: ":exclamation: ログイン情報の漏洩防止のため、メッセージを削除しました。"
        )
        Api.delete_message(msg)

        # DMではメッセージを送れないことがあるので、一旦チャンネルに送信する
        # case Api.create_dm(msg.author.id) do
        #   {:ok, dm_channel} ->
        #     Api.create_message(dm_channel.id,
        #       """
        #       ログイン情報の漏洩防止のため、メッセージを削除しました。削除されたメッセージ：
        #       ```
        #       #{msg.content}
        #       ```
        #       """
        #     )
        # end
      true -> :noop
    end
  end
end
