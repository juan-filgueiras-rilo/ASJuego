defmodule Network do
  use GenServer


  @moduledoc """
    Este módulo recibe un socket ya abierto, e intentará
    utilizarlo para encargarse de sincronizar el estado del
    juego entre dos peers.
  """
  defmodule CombatNetworking do
    
    def init(socket, callback) do
      loop(socket, callback);
    end

    defp loop(socket, callback) do
      result = try do
        json = Socket.Stream.recv!(socket);
        #:timer.sleep(500);
        #IO.puts("Recibi: " <> Kernel.inspect(json));
        if (not is_binary(json)) do
          :ok
        else
          result = case JSON.decode(json) do
            {:ok, json} -> 
              case json["function"] do
                "usarHechizo" ->
                    hechizo = Hechizo.load(json["hechizo"]);
                    Network.hechizo_recibido(callback, hechizo);
                    :ok
                _ -> :error
              end
            
            _x -> :error
          end;
          case result do
            :error -> IO.puts("Error: mensaje no comprendido");
            _ -> :ok;
          end;
          :ok
        end
      rescue
        _x -> 
          IO.puts("Detectada desconexion: " <> Kernel.inspect(_x));
          :disconnect
      end
      if (result != :disconnect) do
        loop(socket, callback)
      end
      
    end
  end


  @moduledoc """
    Este módulo se encarga de escuchar en un puerto TCP, para recibir
    conexiones entrantes y ejeutar los métodos correspondientes en el módulo
    Network.
  """
  defmodule SocketNetworking do
    def init(pid_master) do
      spawn(fn -> initloop(pid_master) end)
    end

    def initloop(pid_master) do
      socket = Socket.TCP.listen!(8000, [{:options, [:keepalive]}, {:mode, :passive}]);
      loop(pid_master, socket)
    end

    def loop(pid_master, socket) do
      result = try do
        case socket |> Socket.accept([{:options, [:keepalive]}, {:mode, :passive}]) do
          {:ok, socket} -> socket
        end
      rescue
        _ -> :error
          
      end
      if (result != :error) do
        {:ok, {addr, _port}} = :inet.peername(result)
        spawn(fn -> loop(pid_master, socket) end)
        handle_client(pid_master, result, addr)
      end
        loop(pid_master, socket)
      
      
    end

    def handle_client(pid_master, client, addr) do
      try do
        
        #data = receive do 
         # {:tcp, socket, msg} ->  msg
        #end
        #Socket.TCP.process(client, self());
        {:ok, data} = Socket.Stream.recv(client);
        IO.puts("DATA="<>Kernel.inspect(data));
        {:ok, jsonOptions} = JSON.decode(data)
        
        closeSocket = case jsonOptions["function"] do
          "status" ->
            {:ok, json} = JSON.encode(%{"result" => "ok"});
            Socket.Stream.send!(client, json);
            true
  
          "query fight" ->
            enemyData = Jugador.load(jsonOptions["player"]);
            IO.puts("EnemyData es" <> Kernel.inspect(enemyData));
            GenServer.call(pid_master, {:fightIncoming, enemyData, client, addr});
            false
  
          "Reject fight" ->
            case GenServer.call(pid_master, :getEnemyFinder) do
              :error ->
                :ok
  
              finder ->
                send(finder, :rejected)
            end;
            true;
  
          "Accept fight" ->
            IO.puts("buscando el finder");
            case GenServer.call(pid_master, :getEnemyFinder) do
              :error ->
                :ok
  
              finder ->
                IO.puts("Pepe 24mil");
                player = Jugador.load(jsonOptions["player"])
                send(finder, {:accepted, player})
            end;
            true
  
          "usarHechizo" ->
            hechizo = Hechizo.load(jsonOptions["hechizo"]);
            Network.hechizo_recibido(pid_master, hechizo);
            false
          #"ACK fight"  -> 
            #GenServer.call(pid_master, {:ackIncomingFight});
            #false
        end
             
        if (closeSocket == true) do
          :ok
          #Socket.Stream.close!(client)
        end
      rescue
        _e -> IO.puts("Desconexion" <> Kernel.inspect(_e));
      end
      
      
    end
  end

  @moduledoc """
    Este módulo gestiona el sistema de autodetección entre peers.
    Dicha autodetección se basa en emitir el mensaje "PEER" por las
    direcciones de broadcast de todas las interfaces de red detectadas.
  """
  defmodule PeerAutodetection do

    @moduledoc """
      Este submódulo se encarga de escuchar en un puerto UDP por mensajes
      de autodetección de otros peers. Cuando recibe un mensaje de este estilo,
      se comunica con el módulo "Network" para dar de alta el nuevo peer en la lista
      de peers.
    """
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
              :ok
          end
        rescue
          _ -> :ok
        end

        loop(pidCallback, socket)
      end
    end

    @moduledoc """
      Este módulo se encarga de emitir constantemente mensajes de broadcast
      para poder ser detectado por otros peers.
    """
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

  # Manages the state of the superPeers (disable).
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
        when is_list(superpeers) and
               superpeers != [] ->
          peerList =
            superpeers
            |> Enum.random()
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
          count = Network.get_peer_count(master_pid)

          if count < 20 do
            queryList(master_pid)
            loop(master_pid)
          end

          :ok
      end
    end
  end

  @moduledoc """
    Este módulo se encarga de controlar los monitores que
    gestionan los peers conocidos. Cuando se detecta que un peer
    conocido está caído, el monitor asociado se comunica con este
    módulo para que así este se comunique con el módulo de red y lo
    elimine.
  """
  defmodule DeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network, :unlinked) end)
    end

    defp loop(pid_network, peer) do
      receive do
        {:setpeer, peer} ->
          loop(pid_network, peer)
        {:unsetpeer} ->
          loop(pid_network, :unlinked)
        {:dead, who} ->
          if (who == peer) do
            
          end;
          Network.remove_peer(pid_network, who)
          loop(pid_network, peer)
      end
    end
  end

  @moduledoc """
    Este módulo se encarga de controlar los monitores que
    gestionan los superpeers conocidos. Cuando se detecta que un 
    superpeer conocido está caído, el monitor asociado se comunica
    con este módulo para que así este se comunique con el módulo 
    de red y lo elimine.
  """
  defmodule SuperDeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network) end)
    end

    defp loop(pid_network) do
      receive do
        {:dead, who} ->
          Network.remove_superpeer(pid_network, who)
          loop(pid_network)
      end
    end
  end

  @moduledoc """
    Este módulo existe para poder realizar de forma asíncrona al módulo
    central de red la búsqueda de enemigos. Cuando encuentre un enemigo
    dispuesto a jugar (o en su defecto, agote los posibles peers), se
    lo comunica al módulo "Network"
  """
  defmodule EnemyFinder do
    def init(pid_network, list, player) do
      spawn(fn -> loop(pid_network, list, player) end)
    end

    defp loop(pid_network, [], player) do
      GenServer.call(pid_network, {:establish_Game, :notFound})
    end

    defp loop(pid_network, [peer | peers], player) do
      case attemptFight(peer, player) do
        {:established, enemyData, socket} ->
          try do
            addr = Monitor.get(peer);
            {a,b,c,d} = addr;
            addr = "#{a}.#{b}.#{c}.#{d}";
            #socket = Socket.TCP.connect!(addr, 8000, [{:options, [:keepalive]}, {:mode, :active}]);

            {:ok, json} = JSON.encode(%{
              "function" => "ACK fight"
            });

            Socket.Stream.send(socket, json);

            GenServer.call(pid_network, {:establish_Game, {addr, socket, enemyData}})
          rescue
            _ -> loop(pid_network, peers, player)
          end

        :rejected ->
          loop(pid_network, peers, player)
      end
    end

    defp attemptFight(peer, player) do
      try do
        {a, b, c, d} = Monitor.get(peer)
        addr = "#{a}.#{b}.#{c}.#{d}"
        {:ok, socket} = Socket.TCP.connect!(addr, 8000, [{:options, [:keepalive]}, {:mode, :passive}])

        {:ok, json} =
          JSON.encode(%{
            "function" => "query fight",
            "player" => Jugador.save(player)
          })

        Socket.Stream.send(socket, json)
        pid = self();
        spawn(fn -> 
          :timer.sleep(10000);
          send(pid, {:rejected, player});
        end);
        spawn(fn ->
          Socket.TCP.process(socket, self())
          result = Socket.Stream.recv(socket);
          case result do
            {:ok, msg} ->  IO.puts("FUNCIONA DE UNA PUÑETERA VEZ" <> Kernel.inspect(msg));
            e -> IO.puts("ERROR FATAL PORQUE ME SALE DE LOS HUEVOS " <> Kernel.inspect(e));
          end
         
          send(pid, {:accepted, player})
        end);
        #Socket.Stream.close!(socket)
        #estaba

        {:ok, msg} = Socket.Stream.recv(socket);
        {:ok, json} = JSON.decode(msg);
        IO.puts("hola: "<> Kernel.inspect(json));
        receive do
          {:accepted, player} -> {:established, player, socket}
          {:rejected, player} -> 
            #Socket.Stream.close!(socket);
            :rejected
        after
          10000 -> :rejected
        end
      rescue
        _ -> :rejected
      end
    end
  end

  def handle_info({:tcp_closed, socket}, state)
  do
    IO.puts("Socket cerrado");
    {:noreply, state}
  end

  def handle_info({:tcp, socket, msg}, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr, socket}})
  do
    try do

      {:ok, json} = JSON.decode(msg);
      case json["function"] do
        "usarHechizo" ->
          hechizo = Hechizo.load(json["hechizo"]);
          Network.hechizo_recibido(self(), hechizo);
      end
      {:noreply, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr, socket}}}
      
    rescue
      _ -> {:noreply, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr, socket}}}
    end

  end

  # Loop de
  def init({uIPid}) do
    SocketNetworking.init(self())
    PeerAutodetection.init(self())
    death_manager = DeathManager.init(self())
    # register_to_superpeer()

    super_death_manager = SuperDeathManager.init(self())

    super_list = init_superpeers(super_death_manager)

    # Necesario en estado si queremeos managear SuperPeers
    superPeerManager = SuperPeerManager.init(self())

    {:ok, {uIPid, :unlinked, super_list, [], death_manager, super_death_manager, :notPaired}}
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

  def handle_call(:noAckIncomingFight, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    case pair do
      {:awaitingACK, addr} -> 
        send(uIPid, :no) # Le comunico a la interfaz que entramos en combate
        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, :notPaired}}
      _ -> {:reply, :error, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
    
  end


  def handle_call({:ackIncomingFight}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}) do
    case pair do
      {:awaitingACK, socket, addr} -> 
        send(uIPid, :yes) # Le comunico a la interfaz que entramos en combate
        pid = self();
        spawn(fn -> CombatNetworking.init(socket, pid)end);
        {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr, socket}}}
      _ -> {:reply, :error, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
    
  end


  def handle_call(
        :getEnemyFinder,
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    case pair do
      {:finding, finderPid} ->
        {:reply, finderPid,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}

      _ ->
        {:reply, :error,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call(
        {:add_peer, peer},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    pair2 =
      case pair do
        {:finding, x} -> :finding
        x -> x
      end

    if length(peers) < 50 and pair2 != :finding do
      if !Enum.any?(peers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("Añadiendo peer: " <> Kernel.inspect(peer))

        {:reply, :ok,
         {uIPid, gamePid, superPeers, [Monitor.init(peer, death_manager) | peers], death_manager,
          super_death_manager, pair}}
      else
        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
      end
    else
      {:reply, :no, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call(
        {:remove_peer, peer},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    case pair do
      {:finding, _} ->
        {:reply, :removeOnFindError,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}

      _ ->
        IO.puts("Eliminando peer: " <> Kernel.inspect(peer))

        peers =
          peers
          |> Enum.filter(fn x -> peer != Monitor.get(x) end)

        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call(
        {:add_superpeer, peer},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    if length(superPeers) < 50 do
      if !Enum.any?(superPeers, fn x -> Monitor.get(x) == peer end) do
        IO.puts("Añadiendo superpeer: " <> Kernel.inspect(peer))

        {:reply, :ok,
         {[Monitor.init(peer, super_death_manager) | superPeers], peers, death_manager,
          super_death_manager, pair}}
      else
        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
      end
    else
      {:reply, :no, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call(
        {:remove_superpeer, peer},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    IO.puts("Eliminando superpeer: " <> Kernel.inspect(peer))

    superPeers =
      superPeers
      |> Enum.filter(fn x -> Monitor.get(x) != peer end)

    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def handle_call(
        :get_peers,
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    {:reply, peers |> Enum.map(fn x -> Monitor.get(x) end),
     {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def handle_call(
        :get_superpeers,
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    {:reply, superPeers |> Enum.map(fn x -> Monitor.get(x) end),
     {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def handle_call(
        :count,
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    {:reply, length(peers),
     {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end




  def handle_call({:rejectIncoming}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:incoming, socket, data, addr}})
  do

    {:ok, msg} = JSON.encode(%{
      "function" => "Reject fight"
    });

    {a,b,c,d} = addr;
    addr = "#{a}.#{b}.#{c}.#{d}";
    #socket = Socket.TCP.connect!(addr, 8000, [{:options, [:keepalive]}, {:mode, :active}]);
    Socket.Stream.send!(socket, msg);
    Socket.Stream.close!(socket);
    #estaba
    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, :notPaired}}
  end

  def handle_call({:acceptIncoming}, _from, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:incoming, socket, data, addr}})
  do

    {_pid, player} = GameFacade.ackCombate(gamePid, self(), data);

    {:ok, msg} = JSON.encode(%{
      "function" => "Accept fight",
      "player" => Jugador.save(player)
    });
    {a,b,c,d} = addr;
    addr = "#{a}.#{b}.#{c}.#{d}";
    #socket = Socket.TCP.connect!(addr, 8000, [{:options, [:keepalive]}, {:mode, :active}]);
    Socket.Stream.send!(socket, msg);

    #Socket.Stream.close!(socket);
    #estaba
    pidRed = self();
    spawn(fn -> 
      :timer.sleep(10000);
      GenServer.call(pidRed, :noAckIncomingFight);
    end);

    spawn(fn ->
      try do
        {:ok, msg} = Socket.Stream.recv(socket);
        {:ok, json} = JSON.decode(msg);
        case json["function"] do
          "ACK fight" -> GenServer.call(pidRed, :ackIncomingFight)
          _ -> :error
        end
      rescue
        _ -> :error
      end
    end)

    {:reply, :ok,
     {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:awaitingACK, socket, addr}}}
  end

  def handle_call(
        {:fightIncoming, data, socket, addr},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    case pair do
      :notPaired ->
        send(uIPid, {:fightIncoming, data})

        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager,
          {:incoming, socket, data, addr}}}

      _ ->
        {:reply, :error,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call(
        {:establish_Game, data},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager,
         {:finding, finderPid}}
      ) do
    case data do
      :notFound ->
        send(uIPid, :noGameAvailable)

        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, :notPaired}}

      {addr, socket, enemyData} ->
        send(uIPid, :playerFound)

        GameFacade.synCombate(gamePid)
        GameFacade.ackCombate(gamePid, self(), enemyData)
        pid = self();
        spawn(fn -> CombatNetworking.init(socket, pid)end);

        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, {:paired, addr, socket}}}

      _ ->
        {:reply, :error,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager,
          {:finding, finderPid}}}
    end
  end

  def handle_call(
        {:findGame},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    case pair do
      :notPaired ->
        player = GameFacade.obtenerJugador(gamePid)
        finderPid = EnemyFinder.init(self(), peers, player)

        {:reply, :ok,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager,
          {:finding, finderPid}}}

      _ ->
        {:reply, :error,
         {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
    end
  end

  def handle_call(
        {:setGamePid, pid},
        _from,
        {uIPid, :unlinked, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    {:reply, :ok, {uIPid, pid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def set_GamePid(pid_network, gamePid) do
    GenServer.call(pid_network, {:setGamePid, gamePid})
  end

  def add_superpeer(pid_network, pid) do
    GenServer.call(pid_network, {:add_superpeer, pid})
  end

  def remove_superpeer(pid_network, pid) do
    GenServer.call(pid_network, {:remove_superpeer, pid})
  end

  def findGame(pid_network) do
    GenServer.call(pid_network, {:findGame})
  end

  def acceptIncoming(pid_network) do
    GenServer.call(pid_network, {:acceptIncoming})
  end

  def rejectIncoming(pid_network) do
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

  def get_superpeers(pid_network) do
    GenServer.call(pid_network, :get_superpeers)
  end

  def get_peer_count(pid_network) do
    GenServer.call(pid_network, :count)
  end



  def set_game_pid(pid_network, gamePid) do
    GenServer.call(pid_network, {:setGamePid, gamePid})
  end

  def hechizo_propio(pid_network, hechizo) do
    GenServer.call(pid_network, {:sendHechizoPropio, hechizo})
  end

  def handle_call(
        {:sendHechizoPropio, hechizo},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    case pair do
      {:paired, address, socket} ->
       

        {:ok, json} =
          JSON.encode(%{"function" => "usarHechizo", "hechizo" => Hechizo.save(hechizo)})

        socket |> Socket.Stream.send!(json)

        #Socket.close(socket)

      _ ->
        :error
    end

    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
  end

  def hechizo_recibido(pid_network, hechizo) do
    GenServer.call(pid_network, {:recibir_hechizo, hechizo})
  end

  def handle_call(
        {:recibir_hechizo, hechizo},
        _from,
        {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}
      ) do
    GameFacade.usarHechizoRemoto(gamePid, hechizo)
    
    {:reply, :ok, {uIPid, gamePid, superPeers, peers, death_manager, super_death_manager, pair}}
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
  def debug() do
    spawn(fn ->
      loop()
    end)
  end

  defp loop() do
    receive do
      x -> IO.puts("Recibido mensaje: " <> Kernel.inspect(x))
    end

    loop()
  end
end
