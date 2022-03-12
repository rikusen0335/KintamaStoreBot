defmodule KintamaStoreBot.Handler.InteractionHandler do
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction

  alias KintamaStoreBot.Repo
  alias KintamaStoreBot.Struct.State.AuthState
  alias KintamaStoreBot.Schema.Account
  alias KintamaStoreBot.Utils.{DiscordUtils,RiotAuthUtils,ValorantUtils,MementoUtils}
  alias KintamaStoreBot.Api.{RiotAuthApi,ValorantOfficialApi,ImageGeneratorApi}

  import Nostrum.Struct.Embed

  @spec handle_before(%Interaction{}) :: {:ok} | {:error, String.t()}
  def handle_before(interaction) do
    discord_user_id = DiscordUtils.get_user_id(interaction)
    case interaction.data.name do
      "login" ->
        Repo.get_by(Account, discord_user_id: discord_user_id)
        |> case do
          nil -> handle(interaction)
          _struct ->
            Api.create_interaction_response(interaction, %{
              type: 4,
              data: %{
                content: "すでにログインしています",
                flags: 64
              }
            })
            {:error, "Account already exist"}
        end
      _ -> handle(interaction)
    end
  end

  defp handle(%Interaction{type: 2, data: %{name: "logout"}} = interaction) do
    handle_command("logout", interaction, nil, nil)
  end

  # When application command
  # Application commandの時
  defp handle(%Interaction{type: 2} = interaction) do
    cmd_name = interaction.data.name

    discord_user_id = DiscordUtils.get_user_id(interaction)

    check_username_and_password(interaction)
    |> case do
      {nil, nil} ->
        Api.create_interaction_response(interaction, %{
          type: 4,
          data: %{
            content: "ログインを先に行ってください。(`/login`)\nまた、パスワードがこのボットの管理者にめちゃくちゃバレるので気をつけてください。\n\nパスワード生成ツールなどを使用して生成したパスワードを使用することをおすすめします。メモするのを忘れないでください。",
            flags: 64
          }
        })
      {username, password} ->
        Memento.transaction! fn ->
          Memento.Query.select(AuthState, {:==, :discord_user_id, discord_user_id})
          |> Enum.at(0)
          |> case do
            %AuthState{} ->
              MementoUtils.update_state(discord_user_id, %{
                state_name: "auth",
                executed_command: cmd_name,
                username: username,
                password: password
              })

            _ ->
              Memento.Query.write(%AuthState{
                discord_user_id: discord_user_id,
                state_name: "auth",
                executed_command: cmd_name,
                username: username,
                password: password
              })
          end
        end

        auth_client = RiotAuthApi.client("")
        initial_cookie = auth_client |> RiotAuthApi.auth_cookies()

        # Thus auth_request returns token with path, or 2fa response
        # auth_requestは成功時にパスに入ったトークンか、もしくは2段階認証を返す
        %{body: res_body, cookie: mfa_cookie} = auth_client |> RiotAuthApi.auth_request(initial_cookie, username, password)

        case res_body do
          %{"error" => "auth_failure"} ->
            Api.create_interaction_response(interaction, %{
              type: 4,
              data: %{
                content: "ログイン情報が間違っている可能性があります。もう一度お試しください",
                flags: 64
              }
            })
          _ ->
            handle_auth_response(res_body, interaction, mfa_cookie)
        end
    end
  end

  # Get a 2fa code from the modal
  # モーダルから送られてきた2段階認証のコードを取得する
  defp handle(%Interaction{data: %{components: [%{components: [%{custom_id: "2fa_code", type: 4, value: code}], type: 1}]}} = interaction) do
    discord_user_id = DiscordUtils.get_user_id(interaction)

    Memento.transaction! fn ->
      state = case MementoUtils.get_state(discord_user_id) do
        {:ok, state} -> state
        {:error, _} -> IO.puts("Not found")
      end

      case state do
        %AuthState{state_name: "2fa", cookie: cookie, executed_command: cmd_name} ->
          res_body = RiotAuthApi.client("") |> RiotAuthApi.send_2fa_code(cookie, code)
          %{riot_token: token, riot_entitlement: entitlement} = RiotAuthUtils.retrive_token_and_entitlement(res_body)

          check_2fa_code(interaction, token, entitlement, cmd_name)
      end
    end

    {:ok}
  end

  defp handle(_) do
    {:error, "The interaction is not available in this handler"}
  end

  @spec handle_command(String.t(), %Interaction{}, String.t(), String.t()) :: {:ok} | {:error, String.t()}
  defp handle_command("logout", interaction, _token, _entitlement) do
    discord_user_id = DiscordUtils.get_user_id(interaction)

    Repo.get_by(Account, discord_user_id: discord_user_id)
    |> case do
      nil ->
        Api.create_interaction_response(interaction, %{
          type: 4,
          data: %{
            content: "ログインしていないときはログアウトできません",
            flags: 64
          }
        })
      struct ->
        Repo.delete(struct)
        |> case do
          {:ok, _} ->
            # IO.inspect(struct)
            Api.create_interaction_response(interaction, %{
              type: 4,
              data: %{
                content: "正常にログアウトできました",
                flags: 64
              }
            })
          {:error, _} ->
            # IO.inspect(changeset)
            Api.create_interaction_response(interaction, %{
              type: 4,
              data: %{
                content: "ログアウトできませんでした。もう一度お試しください",
                flags: 64
              }
            })
      end
    end
  end

  defp handle_command("login", interaction, token, entitlement) do
    discord_user_id = DiscordUtils.get_user_id(interaction)
    puuid = RiotAuthApi.client(token) |> RiotAuthApi.get_uuid()

    %{game_name: game_name, tagline: tagline} = ValorantOfficialApi.client(token, entitlement) |> ValorantOfficialApi.get_ingame_name(puuid)

    Memento.transaction! fn ->
      %AuthState{username: username, password: password} = case MementoUtils.get_state(discord_user_id) do
        {:ok, state} -> state
        {:error, _} -> IO.puts("Not found")
      end

      Repo.insert(%Account{
        discord_user_id: discord_user_id,
        username: username,
        password: password,
        player_name: "#{game_name}##{tagline}",
      })

      Api.create_interaction_response(interaction, %{
        type: 4,
        data: %{
          content: "#{game_name}##{tagline}として正常にログインできました",
          flags: 64
        }
      })

      MementoUtils.delete_state(discord_user_id)
    end
  end

  defp handle_command("store", interaction, token, entitlement) do
    %{offer_remaining_duration: remaining_time, skins_with_cost: skins_with_cost} = ValorantUtils.get_daily_store(token, entitlement)

    discord_user_id = DiscordUtils.get_user_id(interaction)
    puuid = RiotAuthApi.client(token) |> RiotAuthApi.get_uuid()

    valorant_client = ValorantOfficialApi.client(token, entitlement)
    %{valorant_points: valop, radianite_points: radip} = ValorantOfficialApi.get_wallet(valorant_client, puuid)

    %{player_name: player_name} = Repo.get_by(Account, discord_user_id: discord_user_id)

    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: ":hourglass: 結果を取得中です..."
      }
    })

    daily_store_image = ImageGeneratorApi.client() |> ImageGeneratorApi.generate_daily_store(skins_with_cost)
    |> case do
      {:ok, response} ->
        # IO.inspect(response)
        response.body
      {:error, error} -> IO.inspect(error)
    end

    # Remove unnecessary state record
    Memento.transaction! fn ->
      MementoUtils.delete_state(discord_user_id)
    end

    main_embed = %Nostrum.Struct.Embed{}
    |> put_description(":mag: #{player_name} | **今日のストア** | 残り時間: #{remaining_time}")
    |> put_field("Valorantポイント", valop)
    |> put_field("レディアナイトポイント", radip)
    # |> put_image(daily_store_image)
    |> put_color(431_948)

    case daily_store_image do
      :timeout -> Api.create_message(interaction.channel_id,
        content: ":x: 結果を取得できませんでした。もう一度お試しください。"
      )
      _ -> Api.create_message(interaction.channel_id,
        embed: main_embed,
        file: %{name: "daily_store.png", body: daily_store_image}
      )
    end

    {:ok}
  end

  defp handle_command(cmd_name, _, _, _), do: {:error, "Cannot handle this command (`#{cmd_name}`) with this handler"}

  defp handle_auth_response(%{"type" => "response"} = response_body, interaction, _cookie) do
    discord_user_id = DiscordUtils.get_user_id(interaction)

    Memento.transaction! fn ->
      current_state = Memento.Query.select(AuthState, {:==, :discord_user_id, discord_user_id})
      |> Enum.at(0)

      %{riot_token: token, riot_entitlement: entitlement} = RiotAuthUtils.retrive_token_and_entitlement(response_body)

      handle_command(current_state.executed_command, interaction, token, entitlement)
    end
  end

  defp handle_auth_response(%{"type" => "multifactor"}, interaction, mfa_cookie) do
    discord_user_id = DiscordUtils.get_user_id(interaction)

    Memento.transaction! fn ->
      MementoUtils.update_state(discord_user_id, %{
        state_name: "2fa",
        cookie: mfa_cookie
      })
    end

    Api.create_interaction_response(interaction, %{
      type: 9,
      data: %{
        custom_id: "2fa_code_modal",
        title: "2段階認証",
        components: [%{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "2fa_code",
              label: "認証コードを入力",
              style: 1,
              min_length: 6,
              max_length: 6,
              placeholder: "000000",
              required: true
            }
          ]
        }]
      }
    })

    {:ok}
  end

  @spec check_2fa_code(%Interaction{}, String.t(), String.t(), String.t()) :: {:ok} | {:error, String.t()}
  defp check_2fa_code(interaction, nil, _entitlement, _cmd_name) do
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "2段階認証コードが間違っている可能性があります。もう一度お試しください",
        flags: 64
      }
    })

    {:error, :mfa_code_is_invalid}
  end

  defp check_2fa_code(interaction, token, entitlement, cmd_name) do
    handle_command(cmd_name, interaction, token, entitlement)
  end

  defp check_username_and_password(%Interaction{} = interaction) do
    discord_user_id = DiscordUtils.get_user_id(interaction)
    Repo.get_by(Account, discord_user_id: discord_user_id)
    |> case do
      nil ->
        case interaction.data.options do
          [%{name: "username", value: username}, %{name: "password", value: password}] -> {username, password}
          _ -> {nil, nil}
        end
      %Account{username: username, password: password} ->
        {username, password}
    end
  end
end
