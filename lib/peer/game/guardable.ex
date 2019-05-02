defmodule Guardable do
  @callback save(Guardable) :: String.t()
  @callback load(String.t()) :: Guardable

  defmacro __using__(_params) do
    quote do
      @behaviour Guardable
    end
  end
end
