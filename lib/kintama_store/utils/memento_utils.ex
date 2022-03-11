defmodule KintamaStoreBot.Utils.MementoUtils do
  alias KintamaStoreBot.Struct.State.AuthState

  def get_state(discord_user_id) do
    Memento.Query.select(AuthState, {:==, :discord_user_id, discord_user_id})
    |> Enum.at(0)
    |> case do
      %AuthState{} = state -> {:ok, state}
      _ -> {:error, :not_found}
    end
  end

  def update_state(discord_user_id, changes = %{}) do
    Memento.Query.select(AuthState, {:==, :discord_user_id, discord_user_id})
    |> Enum.at(0)
    |> case do
      %AuthState{} = state ->
        state
        |> struct(changes)
        |> Memento.Query.write()
        |> then(&{:ok, &1})

      _ ->
        {:error, :not_found}
    end
  end

  def delete_state(discord_user_id) do
    Memento.Query.select(AuthState, {:==, :discord_user_id, discord_user_id})
    |> Enum.at(0)
    |> case do
      %AuthState{} = state ->
        state
        |> Memento.Query.delete_record()
        {:ok}

      _ ->
        {:error, :not_found}
    end
  end
end
