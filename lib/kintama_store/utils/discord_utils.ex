defmodule KintamaStoreBot.Utils.DiscordUtils do
  alias Nostrum.Struct.{Interaction}

  def get_user_id(%Interaction{} = interaction) do
    Integer.to_string(interaction.member.user.id)
  end
end
