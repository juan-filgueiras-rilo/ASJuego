defmodule Monitor do
  def init(ip_addr, master_pid) do
    spawn(fn -> loop(ip_addr, master_pid) end)
  end

  def get(monitor_pid) do
    send(monitor_pid, {:get_pid, self()})

    receive do
      {:ok, ip_addr} ->
        ip_addr

      _ ->
        :error

        # code
    end
  end

  defp loop(ip_addr, master_pid) do
    receive do
      {:stop} ->
        :ok

      {:get_pid, pid_to_reply} ->
        send(pid_to_reply, {:ok, ip_addr})
        loop(ip_addr, master_pid)
    after
      10000 ->
        a = check(ip_addr)

        case a do
          :dead ->
            send(master_pid, {:dead, ip_addr})

          :alive ->
            loop(ip_addr, master_pid)
        end

        # code
    end
  end

  defp check(ip_addr) do
    try do
      {:ok, json} = JSON.encode(%{"function" => "status"})

      socket =
        Socket.TCP.connect({ip_addr, 8000})
        |> Socket.Stream.send!(json);
      Socket.Stream.send(socket,json);

      {:ok, json} = Socket.Stream.recv(socket);
      case json["result"] do
        "ok" ->
          :alive
        _ -> :dead
      end
    rescue
      _ -> :dead
    end
  end
end
