defmodule CuaAppTest do
  use ExUnit.Case
  doctest CuaApp

  test "greets the world" do
    assert CuaApp.hello() == :world
  end
end
