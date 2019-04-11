defmodule SuperPeer do
  use GenServer

  def init(_) do
    {:ok, []}
  end

  def terminate(_, db) do
  end

  def fundar() do
    GenServer.start(__MODULE__, :ok, name: :super)
    :ok
  end

  def handle_call({:registrar, node}, from, state) do
    IO.inspect(from)
    {:reply, :ok, [node | state]}
  end

  def handle_call(:pedir_lista, from, state) do
    {:reply, {:ok, state}, state}
  end
end
