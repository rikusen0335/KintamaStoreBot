defmodule KintamaStoreBot.Utils.MementoUtils do
  alias KintamaStoreBot.Struct.Ratelimit
  alias KintamaStoreBot.Struct.State.AuthState

  def get_state(discord_user_id) do
    Memento.Query.select(AuthState, {:==, :discord_user_id, discord_user_id})
    |> Enum.at(0)
    |> case do
      %AuthState{} = state -> {:ok, state}
      _ -> {:error, :not_found}
    end
  end

  def get_ratelimit(discord_user_id) do
    Memento.Query.select(Ratelimit, {:==, :discord_user_id, discord_user_id})
    |> List.first()
    |> case do
      %Ratelimit{} = limit -> {:ok, limit}
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

  def update_ratelimit(discord_user_id) do
    Memento.Query.select(Ratelimit, {:==, :discord_user_id, discord_user_id})
    |> List.first()
    |> case do
      %Ratelimit{} = limit ->
        limit
        |> struct(%{last_executed: System.system_time(:second)})
        |> Memento.Query.write()
        |> then(&{:ok, &1})

      _ ->
        %Ratelimit{discord_user_id: discord_user_id, last_executed: System.system_time(:second)}
        |> Memento.Query.write()
        |> then(&{:ok, &1})
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
