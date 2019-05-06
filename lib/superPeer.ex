defmodule SuperPeer do
  use GenServer

  defmodule DeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network) end)
    end

    defp loop(pid_network) do
      receive do
        {:dead, who} ->
          SuperPeer.borrar(pid_network, who)
          loop(pid_network)
      end
    end
  end

  def init(_) do
    death_manager = DeathManager.init(self())
    {:ok, {[], death_manager}}
  end

  def terminate(_, db) do
  end

  def fundar() do
    GenServer.start(__MODULE__, :ok, name: :super)
  end

  def handle_call({:registrar}, {node, _reference}, {list, death_manager}) do
    IO.inspect(node)
    Monitor.init(node, death_manager)
    {:reply, :ok, {[node | list], death_manager}}
  end

  def handle_call({:pedir_lista}, {node, _reference}, {list, death_manager}) do
    filterdList = Enum.filter(list, fn x -> x != node end)
    {:reply, {:ok, filterdList}, {list, death_manager}}
  end

  def handle_call({:delete_node, node}, {_who, _reference}, {list, death_manager}) do
    {:reply, {:ok}, {Enum.filter(list, fn x -> x != node end), death_manager}}
  end

  def pedir_lista(willyrex) do
    GenServer.call(willyrex, {:pedir_lista})
  end

  def registrar(willyrex) do
    GenServer.call(willyrex, {:registrar})
  end

  def borrar(willyrex, who) do
    GenServer.call(willyrex, {:delete_node, who})
  end
end
