defmodule Network do
  use GenServer

  defmodule SocketNetworking do
    def init(pid_master) do
      socket = Socket.TCP.listen!(8000)
      spawn(fn -> loop(pid_master, socket) end)
    end

    def loop(pid_master, socket) do
      client = socket |> Socket.accept!()
      {:ok, {addr, _port}} = :inet.peername(client);
      spawn(fn -> handle_client(pid_master, client, addr) end)
      loop(pid_master, socket)
    end

    def handle_client(pid_master, client, addr) do
      data = Socket.Stream.recv!(client)
      {:ok, jsonOptions} = JSON.decode(data)


      case jsonOptions["function"] do
        "status" ->
          {:ok, json} = JSON.encode(%{"result" => "ok"})
          Socket.Stream.send!(client, json)
        "query fight" ->
          enemyData = Jugador.load(jsonOptions["player"]);
          GenServer.call(pid_master, {:fightIncoming, enemyData, client, addr});
        "Reject fight" ->
          case GenServer.call(pid_master, :getEnemyFinder) do
            :error ->
              :ok;
            finder ->
              send(finder, :rejected);
          end
        "Accept fight" ->
          case GenServer.call(pid_master, :getEnemyFinder) do
            :error ->
              :ok;
            finder ->
              player = Jugador.load(jsonOptions["player"]);
              send(finder, {:accepted, player});
          end
        "ACK fight" ->
          :ok;
          GenServer.call(pid_master, :ackIncomingFight)
        
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
        try do
          {data, client} = socket |> Socket.Datagram.recv!()
          {:ok, list} = :inet.getif()
          list = list |> Enum.map(fn {x, _, _} -> x end)
          {client, _port} = client

          case data do
            "PEER" ->
              if list |> Enum.all?(fn x -> x != client end) do
                Network.add_peer(pidCallback, client)
              end
            "SUPERPEER" ->
              if list |> Enum.all?(fn x -> x != client end) do
                Network.add_superpeer(pidCallback, client)
              end
            _x ->
              :ok;
          end
        rescue
          _ -> :ok;
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
          Network.remove_superpeer(pid_network, who);
          loop(pid_network)
      end
    end
  end


  defmodule EnemyFinder do
    def init(pid_network, list, player) do
      spawn(fn -> loop(pid_network, list, player) end);
    end

    defp loop(pid_network, [], player) do
      GenServer.call(pid_network, {:establish_Game, :notFound});
    end

    defp loop(pid_network, [peer | peers], player) do
      case attemptFight(peer, player) do
        {:established, enemyData} ->
          GenServer.call(pid_network, {:establish_Game, {peer, enemyData}})
        :rejected ->
          loop(pid_network, peers, player)
      end
    end

    

    defp attemptFight(peer, player)
    do
      {a,b,c,d} = Monitor.get(peer);
      addr = "#{a}.#{b}.#{c}.#{d}";
      socket = Socket.TCP.connect!(addr, 8000);

      {:ok, json} = JSON.encode(%{
        "function" => "query fight",
        "player" => Jugador.save(player)
      });
      Socket.Stream.send(socket, json);
      Socket.Stream.close!(socket);


      loopAwaitAnswer(player)
    end

    defp loopAwaitAnswer(player) do
      IO.puts("ESTO POR QUE?");
      :timer.sleep(10000);
      receive do
        {:accepted, playerAccepted} -> 
          case player do
            playerAccepted -> {:established, player}
            _ -> loopAwaitAnswer(player)
          end
        :rejected -> :rejected
      after 1 -> :rejected
      end
    end

  end

  # Loop de
  def init({uIPid}) do
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

    {:ok, {uIPid, :unlinked,super_list, [], death_manager, super_death_manager, :notPaired}}
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

  def handle_call(:getEnemyFinder, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    case pair do
      {:finding, finderPid} -> {:reply, finderPid, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
      _ -> {:reply, :error, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end

  end

  def handle_call({:add_peer, peer}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    pair2 = case pair do
      {:finding, x} -> :finding
      x -> x
    end
    if ((length(peers) < 50) and (pair2 != :finding)) do


      if !Enum.any?(peers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("Añadiendo peer: " <> Kernel.inspect(peer))

        {:reply, :ok, {uIPid, gamePid, superPeers, [Monitor.init(peer, death_manager) | peers], death_manager, super_death_manager, pair}}
      else

        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
      end
    else
      {:reply, :no, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call({:remove_peer, peer}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    case pair do
      {:finding, _} -> {:reply, :removeOnFindError, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
      _ ->
        IO.puts("Eliminando peer: " <> Kernel.inspect(peer));
        peers =
          peers
          |> Enum.filter(fn x -> peer != Monitor.get(x) end)

        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end

  end

  def handle_call({:add_superpeer, peer}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    if length(superPeers) < 50 do


      if !Enum.any?(superPeers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("Añadiendo superpeer: " <> Kernel.inspect(peer))

        {:reply, :ok, {[Monitor.init(peer, super_death_manager) | superPeers], peers, death_manager, super_death_manager, pair}}
      else

        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
      end
    else
      {:reply, :no, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call({:remove_superpeer, peer}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    IO.puts("Eliminando superpeer: " <> Kernel.inspect(peer));
    superPeers =
      superPeers
      |> Enum.filter(fn x -> Monitor.get(x) != peer end)

    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end


  def handle_call(:get_peers, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    {:reply, peers |> Enum.map(fn x -> Monitor.get(x) end), {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def handle_call(:get_superpeers, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    {:reply, superPeers |> Enum.map(fn x -> Monitor.get(x) end), {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def handle_call(:count, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    {:reply, length(peers), {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def handle_call(:get_superPeers, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    {:reply, {:ok, superPeers}, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end


  def handle_call({:rejectIncoming}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:incoming, socket, data, addr}})
  do

    {:ok, msg} = JSON.encode(%{
      "function" => "Reject fight"
    });
    Socket.Stream.send!(socket, msg);
    Socket.Stream.close!(socket);

    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, :notPaired}}
  end

  def handle_call({:acceptIncoming}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:incoming, socket, data, addr}})
  do

    {_pid, player} = GameFacade.ackCombate(gamePid, self(), data);

    {:ok, msg} = JSON.encode(%{
      "function" => "Accept fight",
      "player" => Jugador.save(player)
    });
    IO.inspect(addr);
    {a,b,c,d} = addr;
    addr = "#{a}.#{b}.#{c}.#{d}";
    socket = Socket.TCP.connect!(addr, 8000);
    Socket.Stream.send!(socket, msg);
    Socket.Stream.close!(socket);





    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr}}}
  end

  def handle_call({:fightIncoming, data, socket, addr}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    case pair do
      :notPaired ->
        send(uIPid, {:fightIncoming, data});
        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:incoming, socket, data, addr}}}
      _ ->
        {:reply, :error, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call({:establish_Game, data}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:finding, finderPid}})
  do
    case data do
      :notFound ->
        send(uIPid, :noGameAvailable);
        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, :notPaired}}
      {addr, enemyData} ->

        {a,b,c,d} = Monitor.get(addr);
        addr = "#{a}.#{b}.#{c}.#{d}";
        socket = Socket.TCP.connect!(addr, 8000);

        {:ok, json} = JSON.encode(%{
          "function" => "ACK fight"
        });
        Socket.Stream.send(socket, json);
        Socket.Stream.close!(socket);

        send(uIPid, :playerFound);

        GameFacade.synCombate(gamePid);
        GameFacade.ackCombate(gamePid, self(), enemyData);

        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr}}}

      _ ->
        {:reply, :error, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:finding, finderPid}}}
    end
  end


  def handle_call({:findGame}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair})
  do
    case pair do
      :notPaired ->
        player = GameFacade.obtenerJugador(gamePid);
        finderPid = EnemyFinder.init(self(), peers, player);
        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:finding, finderPid}}}
      _ -> {:reply, :error, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call({:setGamePid, pid}, _from, {uIPid, :unlinked, superPeers, peers, death_manager, super_death_manager, pair})
  do
    {:reply, :ok, {uIPid, pid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def set_GamePid(pid_network,gamePid) do
    GenServer.call(pid_network, {:setGamePid,gamePid})
  end
  def add_superpeer(pid_network, pid)
  do
    GenServer.call(pid_network, {:add_superpeer, pid})
  end

  def remove_superpeer(pid_network, pid)
  do
    GenServer.call(pid_network, {:remove_superpeer, pid})
  end


  def findGame(pid_network)
  do
    GenServer.call(pid_network, {:findGame})
  end

  def acceptIncoming(pid_network)
  do
    GenServer.call(pid_network, {:acceptIncoming})
  end

  def rejectIncoming(pid_network)
  do
    GenServer.call(pid_network, {:rejectIncoming})
  end

  def add_peer(pid_network, pid) do
    GenServer.call(pid_network, {:add_peer, pid})
  end

  def remove_peer(pid_network, pid) do
    GenServer.call(pid_network, {:remove_peer, pid})
  end

  def get_peers(pid_network) do
    GenServer.call(pid_network, :get_peers)
  end

  def get_superpeers(pid_network)
  do
    GenServer.call(pid_network, :get_superpeers)
  end

  def get_peer_count(pid_network) do
    GenServer.call(pid_network, :count)
  end

  def get_superpeers(pid_network) do
    GenServer.call(pid_network, :get_superPeers)
  end

  def set_game_pid(pid_network, gamePid) do
    GenServer.call(pid_network, {:setGamePid, gamePid})
  end


  def initialize(uIPid) do
    try do
      {_status, pid} = GenServer.start(Network, {uIPid})
      pid
    rescue
      _ -> IO.puts("Error lanzando modulo de red")
    end
  end
end


defmodule DebugGuay do
  def debug()
  do
    spawn(fn ->
      loop()
    end)
  end

  defp loop()
  do
    receive do
      x -> IO.puts("Recibido mensaje: " <> Kernel.inspect(x));
    end
    loop()
  end
end
