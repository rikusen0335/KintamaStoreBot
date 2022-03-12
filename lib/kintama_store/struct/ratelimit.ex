defmodule KintamaStoreBot.Struct.Ratelimit do
  use Memento.Table,
    attributes: [:id, :discord_user_id, :last_executed],
    index: [:discord_user_id],
    type: :ordered_set,
    autoincrement: true
end
