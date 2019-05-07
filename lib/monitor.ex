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
            send(master_pid, {:dead, self()})

          :alive ->
            loop(ip_addr, master_pid)
        end

        # code
    end
  end

  defp check(ip_addr) do
    {ip, _port} = ip_addr
    {:ok, json} = JSON.encode(%{"function" => "status"})

    socket =
      Socket.TCP.connect({ip, 8000})
      |> Socket.Stream.send!(json)
    Socket.Stream.
    case ip_addr.ping(ip_addr) do
      :pang ->
        :dead

      :pong ->
        :alive
    end
  end
end
