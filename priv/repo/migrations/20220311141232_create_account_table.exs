defmodule KintamaStoreBot.Repo.Migrations.CreateAccountTable do
  use Ecto.Migration

  def change do
    create table(:account) do
      add :discord_user_id, :string
      add :username,        :string
      add :password,        :string
      add :player_name,     :string
    end

    create unique_index(:account,  [:discord_user_id], name: :account_discord_user_id_index)
  end
end
