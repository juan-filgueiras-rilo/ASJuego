defmodule SuperPeer do
  use GenServer

  def init(_) do
    {:ok, {[], 0}}
  end

  def terminate(_, db) do
  end

  def fundar() do
    GenServer.start(__MODULE__, :ok, name: :super)
    :ok
  end

  def handle_call({:registrar, node}, from, {list, counter}) do
    IO.inspect(from)

    {:reply, {:ok, counter}, {[{node, counter} | list], counter + 1}}
  end

  def handle_call({:pedir_lista, nodeOrigin}, _from, {list, counter}) do
    filterdList = Enum.filter(list, fn {node, _} -> node != nodeOrigin end)
    {:reply, {:ok, filterdList}, {list, counter}}
  end

  def handle_call({:delete_node, nodeOrigin}, _from, {list, counter}) do
    {:reply, {:ok}, {Enum.filter(list, fn node -> node != nodeOrigin end)}}
  end
end
