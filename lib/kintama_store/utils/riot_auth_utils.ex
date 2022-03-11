defmodule KintamaStoreBot.Utils.RiotAuthUtils do
  use GenServer
  use Tesla

  alias Nostrum.Api

  alias KintamaStoreBot.Repo
  alias KintamaStoreBot.Schema.Account
  alias KintamaStoreBot.Api.{RiotAuthApi,RiotTokenApi,ValorantOfficialApi}
  alias KintamaStoreBot.Utils.{DiscordUtils}

  defp handle_authentication(interaction, %{"type" => "multifactor"}) do
    IO.puts("Proceeding 2FA...")

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
  end

  defp handle_authentication(interaction, %{"type" => "response"} = response_body) do
    IO.puts("Proceeding normal authentication...")

    %{riot_token: token, riot_entitlement: entitlement} = retrive_token_and_entitlement(response_body)
    puuid = RiotAuthApi.client(token) |> RiotAuthApi.get_uuid()

    discord_user_id = DiscordUtils.get_user_id(interaction)
    %{username: username, password: password} = Repo.get_by(ValorantAuth, discord_user_id: discord_user_id)

    case entitlement do
      nil ->
        [
          content: "ログイン情報が間違っている可能性があります",
          ephemeral?: true
        ]
      _ ->
        %{game_name: game_name, tagline: tagline} = ValorantOfficialApi.client(token, entitlement) |> ValorantOfficialApi.get_ingame_name(puuid)

        Repo.get_by(Account, discord_user_id: discord_user_id)
        |> case do
          nil ->
            Repo.insert(%Account{
              discord_user_id: discord_user_id,
              username: username,
              password: password,
              player_name: "#{game_name}##{tagline}",
            })
          struct ->
            Ecto.Changeset.change(struct, player_name: "#{game_name}##{tagline}")
            |> Repo.update()
            |> case do
              {:ok, struct} -> IO.inspect(struct, label: "Successfully updated Valorant auth data")
              {:error, changeset} -> IO.inspect(changeset, label: "Failed to updatte the Valorant auth data")
            end
        end

        [
          content: "#{game_name}##{tagline}として正常にログインできました",
          ephemeral?: true
        ]
    end
  end

  defp handle_authentication(interaction, response_body) do
    IO.inspect(response_body, label: "I have no idea what to do with this response")
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "ログインに失敗しました。もう一度お試しください"
      }
    })
  end

  @spec retrive_token_and_entitlement(Tesla.Env.body()) :: %{riot_entitlement: String.t(), riot_token: String.t()}
  def retrive_token_and_entitlement(response_body) do
    response_body |> get_riot_access_token()
    |> case do
      nil ->
        %{
          riot_token: nil,
          riot_entitlement: nil,
        }
      riot_token ->
        token_client = riot_token |> RiotTokenApi.client()
        riot_entitlement = token_client |> RiotTokenApi.get_riot_entitlement()

        %{
          riot_token: riot_token,
          riot_entitlement: riot_entitlement,
        }
    end
  end

  @doc """
  Return authenticated, or 2FA request
  """
  def request_login(interaction, username, password) do
    discord_user_id = DiscordUtils.get_user_id(interaction)
    auth_client = RiotAuthApi.client("")
    initial_cookie = auth_client |> RiotAuthApi.auth_cookies()

    # Thus auth_request returns token with path, or 2fa response
    # auth_requestは成功時にパスに入ったトークンか、もしくは2段階認証を返す
    auth_client
    |> RiotAuthApi.auth_request(initial_cookie, username, password)
    |> case do
      {:ok, _res} ->
        Repo.get_by(Account, discord_user_id: discord_user_id)
        |> case do
          nil ->
            Repo.insert(%Account{discord_user_id: discord_user_id, username: username, password: password})

        end
    end
    # auth_client
    # |> RiotAuthApi.auth_request(initial_cookie, username, password)
    # |> case do
    #   {:ok, res} ->
    #     Repo.get_by(ValorantAuth, discord_user_id: discord_user_id)
    #     |> case do
    #       nil ->
    #         Repo.insert(%ValorantAuth{discord_user_id: discord_user_id, username: username, password: password})
    #         |> case do
    #           {:ok, _struct} -> IO.puts("Successfully saved username and password")
    #           {:error, changeset} -> IO.inspect(changeset, label: "Failed to save username and password")
    #         end
    #       _ -> IO.puts("Data exists. Continue proceeding")
    #     end

    #     # tfa = 2fa
    #     tfa_cookie = Tesla.get_headers(res, "set-cookie") |> Enum.join(";")

    #     # So we need to overwrite cookie since it's different cookie to use on 2fa
    #     Repo.get_by(CookieSession, discord_user_id: discord_user_id)
    #     |> case do
    #       nil ->
    #         Repo.insert(%CookieSession{discord_user_id: discord_user_id, cookie: tfa_cookie})
    #         |> case do
    #           {:ok, _struct} -> IO.puts("Successfully saved cookie")
    #           {:error, changeset} -> IO.inspect(changeset, label: "Failed to save cookie")
    #         end
    #       struct ->
    #         Repo.delete!(struct)
    #         Repo.insert(%CookieSession{discord_user_id: discord_user_id, cookie: tfa_cookie})
    #         |> case do
    #           {:ok, _struct} -> IO.puts("Successfully saved cookie")
    #           {:error, changeset} -> IO.inspect(changeset, label: "Failed to save cookie")
    #         end
    #     end

    #     handle_authentication(interaction, res.body)
    #   {:error, error} -> IO.inspect(error)
    # end

    # {:ok}
  end

  # @spec login_and_retrive_token_entitlement(String.t(), String.t()) :: %{String.t(), String.t()}
  def login_and_retrive_token_entitlement(interaction, username, password) do
    auth_client = RiotAuthApi.client("")
    cookie = auth_client |> RiotAuthApi.auth_cookies()
    {:ok, riot_token_path} = auth_client
    |> RiotAuthApi.auth_request(cookie, username, password)
    # |> IO.inspect()
    |> case do
      {:ok, res} ->
        case res.body["type"] do
          "multifactor" ->
            IO.puts("bbb")

            # Send a text input in a modal
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

            {:ok, "ok"}

            # call = fn it ->
            #   Api.create_interaction_response(it, %{
            #     type: 4,
            #     data: %{
            #       content: "aaaaa"
            #     }
            #   })
            # end

            # GenServer.cast(__MODULE__, {:stack, interaction_id, call})
          _ -> {:ok, res}
        end
        {:error, error} -> IO.inspect(error)
    end

    riot_token = riot_token_path |> get_riot_access_token()
    token_client = riot_token |> RiotTokenApi.client()
    riot_entitlement = token_client |> RiotTokenApi.get_riot_entitlement()

    %{
      riot_token: riot_token,
      riot_entitlement: riot_entitlement,
    }
  end

  @doc """
  Return token either nil
  トークンか、トークンがなければnilを返す
  """
  def get_riot_access_token(response_body) do
    # Redirect path contains access_token and id_token
    # リダイレクトURLのパラメータにaccess_tokenとid_tokenが格納されている
    try do
      response_body["response"]["parameters"]["uri"]
      |> String.split("&")
      |> Enum.at(0)
      |> String.split("access_token=")
      |> Enum.at(1) # We should have much better way than this but for now it's fine
    rescue
      FunctionClauseError -> nil
    end
  end
end
