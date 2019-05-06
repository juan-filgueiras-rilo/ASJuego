defmodule Monitor do
  def init(pid, master_pid) do
    spawn(fn -> loop(pid, master_pid) end)
  end

  def get(monitor_pid) do
    send(monitor_pid, {:get_pid, self()})

    receive do
      {:ok, pid} ->
        pid

      _ ->
        :error
    after
      1000 ->
        :error

        # code
    end
  end

  defp loop(pid, master_pid) do
    receive do
      {:stop} ->
        :ok

      {:get_pid, pid_to_reply} ->
        send(pid_to_reply, {:ok, pid})
    after
      1000 ->
        case check(pid) do
          :dead ->
            send(master_pid, {:dead, pid})

          :alive ->
            loop(pid, master_pid)
        end

        # code
    end
  end

  defp check(pid) do
    case Node.ping(pid) do
      :pang ->
        :dead

      :pong ->
        :alive
    end
  end
end
