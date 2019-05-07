defmodule Network do
  use GenServer

  # Manages the state of the superPeers
  defmodule SuperPeerManager do
    def init(master_pid) do
      spawn(fn -> initloop(master_pid) end)
    end

    defp initloop(master_pid) do
      IO.inspect("Init Super Loop")

      case Network.get_superpeers(master_pid) do
        {:ok, superpeers} ->
          superpeers
          |> Enum.map(fn x -> Monitor.get(x) end)
          |> Enum.map(fn x -> SuperPeer.registrar(x) end)

          loop(master_pid)

        _ ->
          IO.inspect("WHAT")
          loop(master_pid)
      end

      []
      # TOdos los Nodos de los superPeers
    end

    defp loop(master_pid) do
      receive do
        {:stop} ->
          :ok
      after
        4000 ->
          IO.puts("Looping on SuperPeerManager")

          count =
            Network.get_peer_count(master_pid)
            |> IO.inspect()

          if count < 20 do
            case Network.get_superpeers(master_pid) do
              {:ok, superpeers} ->
                IO.puts("WORKING")
                superpeers

              _ ->
                IO.inspect("what!")
                []
            end
            |> IO.inspect()
            |> Enum.random()
            |> IO.inspect()
            # Esto deberia ser el pid de un momitor

            |> Monitor.get()
            |> IO.inspect()
            # Pedimos Lista a  Random SuperPeer

            |> SuperPeer.pedir_lista()
            # Acutalizamos Nuestra Lista con nuevos peers
            |> Enum.map(fn x -> Network.add_peer(master_pid, x) end)

            loop(master_pid)
          end

          :ok
      end
    end
  end

  # Removes Peers when detects death
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

  # Removes SuperPeers when detects death
  defmodule SuperDeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network) end)
    end

    defp loop(pid_network) do
      receive do
        {:dead, who} ->
          # Network.remove_peer(pid_network, who)
          # Faltaria funcionalidad de anadir/eliminar superPeers
          loop(pid_network)
      end
    end
  end

  # Loop de
  def init(_) do
    death_manager = DeathManager.init(self())
    # register_to_superpeer()
    super_death_manager = SuperDeathManager.init(self())

    super_list =
      init_superpeers(super_death_manager)
      |> IO.inspect()

    # Necesario en estado si queremeos managear SuperPeers
    superPeerManager = SuperPeerManager.init(self())

    {:ok, {super_list, [], death_manager}}
  end

  defp init_superpeers(super_death_manager) do
    # Read config
    path = "./data/SuperPeers.json"

    {:ok, jsonSuperPeers} = File.read(path)

    {:ok, jsonSuperPeers} = JSON.decode(jsonSuperPeers)

    jsonSuperPeers["superpeers"]
    |> Enum.map(fn x -> x["ip"] end)
    |> Enum.map(fn x -> Monitor.init(String.to_atom("super@" <> "#{x}"), super_death_manager) end)
  end

  def handle_call({:add_peer, peer}, _from, {superPeers, peers, death_manager}) do
    if length(peers) < 50 do
      IO.inspect("Inserting new Peer")
      IO.inspect(peer)

      if !Enum.any?(peers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("new")

        {:reply, :ok, {superPeers, [Monitor.init(peer, death_manager) | peers], death_manager}}
      else
        IO.puts("repeated")

        {:reply, :ok, {superPeers, peers, death_manager}}
      end
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
    one_peer =
      peers
      |> Enum.random()
      |> Monitor.get()
      send({:peer,one_peer},{:want_to_connect,Node.self})



    {:reply, {:peer, one_peer}, {superPeers, peers, death_manager}}
  end

  def handle_call(:count, _from, {superPeers, peers, death_manager}) do
    {:reply, length(peers), {superPeers, peers, death_manager}}
  end

  def handle_call(:get_superPeers, _from, {superPeers, peers, death_manager}) do
    IO.puts("Replying the impossible")
    IO.inspect(superPeers)
    {:reply, {:ok, superPeers}, {superPeers, peers, death_manager}}
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
    IO.inspect("trying the impossible")
    IO.inspect(pid_network)
    GenServer.call(pid_network, :get_superPeers)
  end

  def initialize() do
    {_status, pid} = GenServer.start(Network, :ok)
    spawn(fn -> initReceiverLoop() end)
    pid
  end

  def initReceiverLoop() do
    Process.register(self(), :peer)
    receiverLoop()
  end

  def receiverLoop() do
    IO.puts("LOOPER")

    receive do
      _ ->
        IO.puts("aaaaaa")
        receiverLoop()
    end
  end
end
