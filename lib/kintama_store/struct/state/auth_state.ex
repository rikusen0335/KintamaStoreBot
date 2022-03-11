defmodule KintamaStoreBot.Struct.State.AuthState do
  use Memento.Table,
    attributes: [:id, :discord_user_id, :executed_command, :cookie, :state_name, :username, :password],
    index: [:discord_user_id],
    type: :ordered_set,
    autoincrement: true
end
