defmodule KintamaStoreBot.Utils.ApiUtils do
  def return_success_response(res) do
    case res do
      {:ok, response} -> response.body
      {:error, err} -> IO.inspect(err, label: "API request failed:")
    end
  end
end
