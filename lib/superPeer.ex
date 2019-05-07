defmodule SuperPeer do
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
      {data, address} = Socket.Stream.recv(client)
      {:ok, jsonOptions} = JSON.decode(data)

      case jsonOptions["function"] do
        "status" ->
          {:ok, json} = JSON.encode(%{"result" => "ok"})
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
    # Filtramos los que no son la persona pedida
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
