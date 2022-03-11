defmodule KintamaStoreBot.Schema.Account do
  use Ecto.Schema

  # weather is the DB table
  schema "account" do
    field :discord_user_id, :string
    field :username,        :string
    field :password,        :string
    field :player_name,     :string
  end

  def changeset(account, params \\ %{}) do
    account
    |> Ecto.Changeset.cast(params, [:discord_user_id, :username, :password, :player_name])
    |> Ecto.Changeset.unique_constraint(:discord_user_id, name: :account_discord_user_id_index)
  end
end
