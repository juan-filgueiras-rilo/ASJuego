defmodule Network do
  use GenServer

  defmodule SuperPeerManager do
    def init(pid, master_pid) do
      spawn(fn -> loop(pid, master_pid) end)
    end

    defp loop(_pid, master_pid) do
      receive do
        {:stop} ->
          :ok
      after
        10000 ->
          if Network.get_peer_count(master_pid) < 20 do
            superPeer_List = Network.get_superpeers(master_pid)

            Enum.random(superPeer_List)
            |> SuperPeer.pedir_lista()
            |> Enum.map(fn x -> Network.add_peer(master_pid, x) end)
          end

          :ok

          # case check(pid) do
          #   :dead ->
          #     send(master_pid, {:dead, self()})

          #   :alive ->
          #     loop(pid, master_pid)
      end

      # code
    end
  end

  defmodule DeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network) end)
    end

    defp loop(pid_network) do
      receive do
        {:dead, who} ->
          Network.remove_peer(pid_network, who)
          loop(pid_network)
      end
    end
  end

  # State = {:ListaSuperPeers, peers}
  def init(_) do
    death_manager = DeathManager.init(self())
    {:ok, {init_superpeers(), [], death_manager}}
  end

  defp init_superpeers() do
    # Read config
    path = "./data/SuperPeers.json"

    {:ok, jsonSuperPeers} = File.read(path)
    {:ok, jsonSuperPeers} = JSON.decode(jsonSuperPeers)

    jsonSuperPeers['superpeers']
    
    |> Enum.map(fn x -> Monitor.init(String.to_atom("super@" <> "#{x}"), self()) end)
  end

  def handle_call({:add_peer, peer}, _from, {superPeers, peers, death_manager}) do
    if length(peers) < 50 do
      {:reply, :ok, {superPeers, [Monitor.init(peer, death_manager) | peers], death_manager}}
    else
      {:reply, :no, {superPeers, peers, death_manager}}
    end
  end

  def handle_call({:remove_peer, peer}, _from, {superPeers, peers, death_manager}) do
    peers =
      peers
      |> Enum.filter(fn x -> x != Monitor.get(peer) end)

    {:reply, :ok, {superPeers, peers, death_manager}}
  end

  def handle_call(:get_peer, _from, {superPeers, [], death_manager}) do
    {:reply, :error, {superPeers, [], death_manager}}
  end

  def handle_call(:get_peer, _from, {superPeers, peers, death_manager}) do
    one_peer = peers |> Enum.random()

    {:reply, one_peer, {superPeers, peers, death_manager}}
  end

  def handle_call(:count, _from, {superPeers, peers, death_manager}) do
    {:reply, length(peers), {superPeers, peers, death_manager}}
  end

  def handle_call(:get_superPeers, _from, {superPeers, peers, death_manager}) do
    {:reply, superPeers, {superPeers, peers, death_manager}}
  end

  # Gestionar Peers
  # Lista de superPeers statica
  # estado = lista de peers
  # MOnitorizar estado
  # Inicializar con llamada a superPEER
  def add_peer(pid_network, pid) do
    GenServer.call(pid_network, {:add_peer, pid})
  end

  def remove_peer(pid_network, pid) do
    GenServer.call(pid_network, {:remove_peer, pid})
  end

  def get_peer(pid_network) do
    GenServer.call(pid_network, :get_peer)
  end

  def get_peer_count(pid_network) do
    GenServer.call(pid_network, :count)
  end

  def get_superpeers(pid_network) do
    GenServer.call(pid_network, :get_superPeers)
  end

  def initialize() do
    GenServer.start(Network, :ok)
  end
end
