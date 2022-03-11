defmodule KintamaStoreBot.Utils.TimeUtils do
  def seconds_to_hours_minutes_seconds(seconds) do
    { div(seconds, 3600), rem(seconds, 3600) |> div(60),  rem(seconds, 3600) |> rem(60)}
  end
end
