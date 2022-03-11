defmodule KintamaStoreBot.Struct.ImageGenerator.SkinInfo do
  @derive Jason.Encoder
  defstruct [:imageUrl, :name, :cost]
end
