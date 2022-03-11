defmodule KintamaStoreTest do
  use ExUnit.Case
  doctest KintamaStore

  test "greets the world" do
    assert KintamaStore.hello() == :world
  end
end
