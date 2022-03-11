defmodule KintamaStoreBot.Api.ValorantOfficialApi do
  alias KintamaStoreBot.Struct.Valorant.{Offer,Wallet}
  alias KintamaStoreBot.Utils.{ValorantUtils}

  @doc """
  Show current store offer for user
  現在のストアの情報を表示する
  """
  @spec get_storefront(Tesla.Client.t(), String.t()) :: Tesla.Env.result()
  def get_storefront(client, player_uuid) do
    Tesla.get(client, "/store/v2/storefront/" <> player_uuid)
  end

  @spec get_wallet(Tesla.Client.t(), String.t()) :: %Wallet{}
  def get_wallet(client, player_uuid) do
    Tesla.get(client, "/store/v1/wallet/" <> player_uuid)
    |> case do
      {:error, error} -> IO.inspect(error)
      {:ok, response} ->
        balance = response.body["Balances"]

        %Wallet{
          valorant_points: balance["85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741"],
          radianite_points: balance["e59aa87c-4cbf-517a-5983-6e81511be9b7"],
          unknown_points: balance["f08d4ae3-939c-4576-ab26-09ce1f23bb37"],
        }
    end
  end

  @spec get_all_offers(Tesla.Env.client()) :: Tesla.Env.result()
  def get_all_offers(client) do
    response = Tesla.get(client, "/store/v1/offers")

    case response do
      {:ok, data} ->
        IO.puts("Updating valorant offers...")
        IO.inspect(data.body)
        ValorantUtils.update_cache_offers(data.body)
    end

    response
  end

  @doc """
  Find offer by offer_id (same as weapon_skin_level_uuid)
  For checking how cost of a storefront
  オファーのID（weapon_skin_level_uuidと一緒）でオファーを探す
  デイリーストアのコストがどれぐらいか調べる用に使う
  """
  @spec find_offer_by_uuid(Tesla.Client.t(), String.t()) :: %Offer{}
  def find_offer_by_uuid(client, weapon_uuid) do
    cached_offers_response = ValorantUtils.get_all_cached_offers()

    # if no Offers is included in cache, then retrive it from api
    cached_offers = case cached_offers_response do
      {:ok, res} -> res
      {:error, error} -> IO.inspect(error)
    end

    offers = case cached_offers["Offers"] do
      nil ->
        res = get_all_offers(client)
        case res do
          {:ok, r} -> r
        end
      _ -> cached_offers
    end

    case offers do
      nil -> IO.puts("error")
      response ->
        offer = response["Offers"]
        |> Enum.filter(fn offer -> offer["OfferID"] == weapon_uuid end)
        |> Enum.at(0)

        %Offer{
          offer_id: offer["OfferID"],
          is_direct_purchase: offer["IsDirectPurchase"],
          start_date: offer["StartDate"],
          # WARN: Idk what does the id means, this probably break the app in the future
          cost: offer["Cost"]["85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741"],
        }
    end
  end

  def get_ingame_name(client, player_uuid) do
    Tesla.put(client, "/name-service/v2/players", [player_uuid])
    |> case do
      {:ok, response} ->
        # It's api is returning data of array with text/plain, not object with application/json
        body = Jason.decode!(response.body) |> Enum.at(0)
        %{
          display_name: body["DisplayName"],
          subject: body["Subject"],
          game_name: body["GameName"],
          tagline: body["TagLine"],
        }
      _ -> :noop
    end

  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(riot_token, riot_entitlement) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://pd.ap.a.pvp.net"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [
        {"X-Riot-Entitlements-JWT", riot_entitlement},
        {"Content-Type", "application/json"},
      ]},
      {Tesla.Middleware.BearerAuth, token: riot_token},
      Tesla.Middleware.FollowRedirects,
    ]

    Tesla.client(middleware)
  end
end
