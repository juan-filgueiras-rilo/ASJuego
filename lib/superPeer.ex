defmodule SuperPeer do
  use GenServer

  
              


  defmodule SuperPeerAutodetection do
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
                GenServer.call(pidCallback, {:registrar, client})
              end
            "SUPERPEER" -> 
              if list |> Enum.all?(fn x -> x != client end) do
                :ok;
                # AQUI IRIA UN "SUPER_PEER ENCONTRADO"
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
          Socket.Datagram.send!(socket, "SUPERPEER", {{255, 255, 255, 255}, 8000})
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
      {data, address} = Socket.Stream.recv(client)
      {:ok, jsonOptions} = JSON.decode(data)

      case jsonOptions["function"] do
        "status" ->
          IO.puts("Recibi un ping!");
          {:ok, json} = JSON.encode(%{"result" => "ok"});
          Socket.Stream.send!(client, json)

        "register" ->
          case SuperPeer.registrar(address) do
            :ok ->
              {:ok, json} = JSON.encode(%{"result" => "ok"})
              Socket.Stream.send!(client, json)

            _ ->
              {:ok, json} = JSON.encode(%{"result" => "error"})
              Socket.Stream.send!(client, json)
          end

        "pedir_lista" ->
          case SuperPeer.pedir_lista(address) do
            list when is_list(list) ->
              {:ok, json} = JSON.encode(%{"result" => list})
              Socket.Stream.send!(client, json)

            _ ->
              {:ok, json} = JSON.encode(%{"result" => "error"})
              Socket.Stream.send!(client, json)
          end
      end

      Socket.Stream.close!(client)
    end
  end

  defmodule DeathManager do
    def init(pid_network) do
      spawn(fn -> loop(pid_network) end)
    end

    defp loop(pid_network) do
      receive do
        {:dead, who} ->
          IO.puts("Borrando: " <> Kernel.inspect(who));
          SuperPeer.borrar(pid_network, who)
          loop(pid_network)
      end
    end
  end

  def init(_) do
    autodeteccion = SuperPeerAutodetection.init(self());
    death_manager = DeathManager.init(self())
    {:ok, {[], death_manager}}
  end

  def terminate(_, db) do
  end

  def fundar() do
    GenServer.start(__MODULE__, :ok, name: :super)
  end

  def handle_call({:registrar, node}, {_, reference}, {list, death_manager}) do
    if (Enum.all?(list, fn x -> Monitor.get(x) != node end)) do
      IO.puts("Registrando peer: " <> Kernel.inspect(node));
      monitored_pid = Monitor.init(node, death_manager);
      {:reply, :ok, {[monitored_pid | list], death_manager}}
    else
      {:reply, :error, {list, death_manager}}
    end


  end

  def handle_call({:pedir_lista, node}, {_who, _reference}, {list, death_manager}) do
    # Filtramos los que no son la persona pedida
    filterdList =
      list
      |> Enum.map(fn x -> Monitor.get(x) end)
      |> Enum.filter(fn x -> x != node end);
    
    {:reply, filterdList, {list, death_manager}}

  end

  def handle_call({:delete_node, monitor_pid}, {_who, _reference}, {list, death_manager}) do
    IO.puts("Eliminando nodo: " <> Kernel.inspect(monitor_pid));

    list = list |> Enum.filter(fn x -> case Monitor.get(x) do 
      :error -> false
      monitor_pid -> false
      _ -> true
    end end);
    {:reply, {:ok}, {list, death_manager}}
  end

  def pedir_lista(willyrex) do
    try do
      addr = {willyrex, 8000};
      socket = Socket.TCP.connect!(addr);

      {:ok, msg} = JSON.encode(%{
        "function" => "pedir_lista"
      });
      Socket.Stream.send!(socket, msg);

      {:ok, answer} = JSON.decode(Socket.Stream.recv!(socket));
      case answer["result"] do
        "error" -> :error
        list -> list
      end
    rescue
      _ -> :error
    end
  end

  def registrar(willyrex) do
    try do
      addr = {willyrex, 8000};
      socket = Socket.TCP.connect!(addr);

      {:ok, msg} = JSON.encode(%{
        "function" => "register"
      });
      Socket.Stream.send!(socket, msg);

      {:ok, answer} = JSON.decode(Socket.Stream.recv!(socket));
      case answer["result"] do
        "ok" -> :ok
        "error" -> :error
      end
    rescue
      _ -> :error
    end
    
  end

  @doc """
    Elimina un superpeer de la lista. Solo puede ser llamado localmente.
  """
  def borrar(willyrex, who) do
    GenServer.call(willyrex, {:delete_node, who})
  end
end
