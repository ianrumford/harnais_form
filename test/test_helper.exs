ExUnit.start()

defmodule HarnaisFormHelperTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: true
      use Harnais
      alias Harnais.Error, as: HEE
      alias Harnais.Error.Status, as: HES

      use Harnais.Attribute
      use Harnais.Attribute.Data
    end
  end
end
