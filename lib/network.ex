defmodule Network do
  use GenServer

  defmodule SocketNetworking do
    def init(pid_master) do
      socket = Socket.TCP.listen!(8000)
      spawn(fn -> loop(pid_master, socket) end)
    end

    def loop(pid_master, socket) do
      client = socket |> Socket.accept!()
      spawn(fn -> handle_client(client) end)
      loop(pid_master, socket)
    end

    def handle_client(client) do
      data = Socket.Stream.recv!(client)
      {:ok, jsonOptions} = JSON.decode(data)

      case jsonOptions["function"] do
        "status" ->
          {:ok, json} = JSON.encode(%{"result" => "ok"})
          Socket.Stream.send!(client, json)
      end

      Socket.Stream.close!(client)
    end
  end

  defmodule PeerAutodetection do
    defmodule Listener do
      def init(pidCallback, socket) do
        loop(pidCallback, socket)
      end

      defp loop(pidCallback, socket) do
        {data, client} = socket |> Socket.Datagram.recv!()
        {:ok, list} = :inet.getif()
        list = list |> Enum.map(fn {x, _, _} -> x end)
        {client, _port} = client

        case data do
          "PEER" -> 
            if list |> Enum.all?(fn x -> x != client end) do
              IO.puts("ENCONTRADO PEER EN: " <> Kernel.inspect(client))
              Network.add_peer(pidCallback, client)
            end
          "SUPERPEER" -> 
            if list |> Enum.all?(fn x -> x != client end) do
              IO.puts("ENCONTRADO SUPERPEER EN: " <> Kernel.inspect(client));
              Network.add_superpeer(pidCallback, client)
            end
          _x -> 
            IO.puts("Mensaje");
            :ok;
        end
        loop(pidCallback, socket)
      end
    end

    defmodule Beacon do
      def init(socketsList) do
        loop(socketsList)
      end

      defp loop(socketsList) do
        announce(socketsList)

        receive do
          :stop -> :ok
        after
          10000 -> loop(socketsList)
        end
      end

      defp announce(socketsList) do
        socketsList
        |> Enum.map(fn {socket, broadcast} ->
          Socket.Datagram.send!(socket, "PEER", {{255, 255, 255, 255}, 8000})
        end)
      end
    end

    def init(pidCallback) do
      try do
        {:ok, listenSocket} =
          Socket.UDP.open(8000, [{:broadcast, true}, {:local, [{:address, {0, 0, 0, 0}}]}])

        {:ok, interfaces} = :inet.getif()

        sendSocketsList =
          interfaces
          |> Enum.map(fn {ip, broadcast, _} ->
            {:ok, socket} =
              Socket.UDP.open(10000, [{:broadcast, true}, {:local, [{:address, ip}]}])

            {
              socket,
              broadcast
            }
          end)

        listener = spawn(fn -> Listener.init(pidCallback, listenSocket) end)
        beacon = spawn(fn -> Beacon.init(sendSocketsList) end)
      rescue
        x -> IO.puts("Imposible cargar sistema de autodeteccion: " <> Kernel.inspect(x))
      end
    end
  end

  # Manages the state of the superPeers
  defmodule SuperPeerManager do
    def init(master_pid) do
      spawn(fn -> initloop(master_pid) end)
    end

    defp initloop(master_pid) do
      case Network.get_superpeers(master_pid) do
        {:ok, superpeers} ->
          superpeers
          |> Enum.map(fn x -> Monitor.get(x) end)
          |> Enum.map(fn x -> SuperPeer.registrar(x) end)

        _ ->
          :ok
      end

      loop(master_pid)

      # TOdos los Nodos de los superPeers
    end

    defp queryList(master_pid) do
      
      
      case Network.get_superpeers(master_pid) do
        {:ok, superpeers} 
          when is_list(superpeers)
          and superpeers != []->
          
          #IO.puts("WORKING")
          peerList = superpeers |> Enum.random()
          |> Monitor.get()
          |> SuperPeer.pedir_lista()
          case peerList do
            :error -> :error
            list -> Enum.map(list, fn x -> Network.add_peer(master_pid, x) end)
          end 
        _ ->
          #IO.inspect("what!")
          :ok
      end
    end

    defp loop(master_pid) do
      receive do
        {:stop} ->
          :ok
      after
        4000 ->
          count =
            Network.get_peer_count(master_pid)

          if count < 20 do
            queryList(master_pid);
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
    IO.puts("Lanzado");
    SocketNetworking.init(self());
    PeerAutodetection.init(self());
    death_manager = DeathManager.init(self());
    # register_to_superpeer()
    super_death_manager = SuperDeathManager.init(self())

    super_list =
      init_superpeers(super_death_manager)

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
      

      if !Enum.any?(peers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("Añadiendo peer: " <> Kernel.inspect(peer))

        {:reply, :ok, {superPeers, [Monitor.init(peer, death_manager) | peers], death_manager}}
      else

        {:reply, :ok, {superPeers, peers, death_manager}}
      end
    else
      {:reply, :no, {superPeers, peers, death_manager}}
    end
  end

  def handle_call({:remove_peer, peer}, _from, {superPeers, peers, death_manager}) do
    IO.puts("Eliminando peer: " <> Kernel.inspect(peer));
    peers =
      peers
      |> Enum.filter(fn x -> peer != Monitor.get(x) end)

    {:reply, :ok, {superPeers, peers, death_manager}}
  end

  def handle_call({:add_superpeer, peer}, _from, {superPeers, peers, death_manager}) do
    if length(superPeers) < 50 do
      

      if !Enum.any?(superPeers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("Añadiendo superpeer: " <> Kernel.inspect(peer))

        {:reply, :ok, {[Monitor.init(peer, death_manager) | superPeers], peers, death_manager}}
      else

        {:reply, :ok, {superPeers, peers, death_manager}}
      end
    else
      {:reply, :no, {superPeers, peers, death_manager}}
    end
  end
  
  def handle_call({:remove_superpeer, peer}, _from, {superPeers, peers, death_manager}) do
    IO.puts("Eliminando superpeer: " <> Kernel.inspect(peer));
    superPeers =
      superPeers
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

    send({:peer, one_peer}, {:want_to_connect, Node.self()})

    {:reply, {:peer, one_peer}, {superPeers, peers, death_manager}}
  end

  def handle_call(:count, _from, {superPeers, peers, death_manager}) do
    {:reply, length(peers), {superPeers, peers, death_manager}}
  end

  def handle_call(:get_superPeers, _from, {superPeers, peers, death_manager}) do
    {:reply, {:ok, superPeers}, {superPeers, peers, death_manager}}
  end


  def add_superpeer(pid_network, pid) 
  do
    GenServer.call(pid_network, {:add_superpeer, pid})
  end

  def remove_superpeer(pid_network, pid)
  do
    GenServer.call(pid_network, {:remove_superpeer, pid})
  end

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
    try do
      {_status, pid} = GenServer.start(Network, :ok)
      pid
    rescue
      _ -> IO.puts("Error lanzando modulo de red")
    end
  end
end
