defmodule SuperPeer do
  use GenServer

  defmodule DeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network) end)
    end

    defp loop(pid_network) do
      receive do
        {:dead, who} ->
          IO.inspect("Who dead")
          IO.inspect(who)
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

  def handle_call({:registrar, node}, {_, reference}, {list, death_manager}) do
    monitored_pid = Monitor.init(node, death_manager)

    {:reply, :ok, {[monitored_pid | list], death_manager}}
  end

  def handle_call({:pedir_lista, node}, {_who, _reference}, {list, death_manager}) do
    IO.inspect("Lista Pedida")
    IO.inspect(node)
    #Filtramos los que no son la persona pedida
    filterdList =
      list
      |> Enum.map(fn x -> Monitor.get(x) end)
      |> Enum.filter(fn x -> x != node end)

    {:reply, filterdList, {list, death_manager}}
  end

  def handle_call({:delete_node, monitor_pid}, {_who, _reference}, {list, death_manager}) do
    {:reply, {:ok}, {Enum.filter(list, fn x -> x != monitor_pid end), death_manager}}
  end

  def pedir_lista(willyrex) do
    GenServer.call({:super, willyrex}, {:pedir_lista, Node.self()})
  end

  def registrar(willyrex) do
    GenServer.call({:super, willyrex}, {:registrar, Node.self()})
  end

  def borrar(willyrex, who) do
    GenServer.call(willyrex, {:delete_node, who})
  end
end
