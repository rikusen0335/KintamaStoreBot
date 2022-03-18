defmodule KintamaStoreBot.Utils.DiscordUtils do
  alias Nostrum.Api
  alias Nostrum.Struct.{Interaction}

  def get_user_id(%Interaction{} = interaction) do
    Integer.to_string(interaction.member.user.id)
  end

  def get_guild_id(%Interaction{} = interaction) do
    Integer.to_string(interaction.guild_id)
  end

  def apply_guild_commands(guild_id) do
    login = %{
      name: "login",
      description: "Riotアカウントにログインします",
      options: [
        %{
          # ApplicationCommandType::STRING
          type: 3,
          name: "username",
          description: "RiotアカウントのID（Valorant#1234形式じゃないただのID）",
          required: true
        },
        %{
          # ApplicationCommandType::STRING
          type: 3,
          name: "password",
          description: "Riotアカウントのパスワード",
          required: true
        },
      ]
    }

    logout = %{
      name: "logout",
      description: "いまログインしているアカウントの情報を削除します",
    }

    store = %{
      name: "store",
      description: "いまログインしているアカウントの今日のストアを確認します",
    }

    Api.create_guild_application_command(guild_id, login) |> IO.inspect()
    Api.create_guild_application_command(guild_id, logout) |> IO.inspect()
    Api.create_guild_application_command(guild_id, store) |> IO.inspect()

    {:ok}
  end

  def remove_guild_commands(guild_id) do
    {:ok, guild_commands} = Api.get_guild_application_commands(guild_id)
    Enum.each(guild_commands, fn cmd -> Api.delete_guild_application_command(guild_id, cmd.id) end)

    {:ok, global_commands} = Api.get_global_application_commands()
    Enum.each(global_commands, fn cmd -> Api.delete_global_application_command(cmd.id) end)

    {:ok}
  end
end
