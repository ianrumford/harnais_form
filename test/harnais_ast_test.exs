defmodule HarnaisAstTest do
  use ExUnit.Case
  doctest HarnaisAst

  test "greets the world" do
    assert HarnaisAst.hello() == :world
  end
end
