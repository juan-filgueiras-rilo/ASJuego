defmodule Monitor do
  def init(node, master_pid) do
    spawn(fn -> loop(node, master_pid) end)
  end

  def get(monitor_pid) do
    send(monitor_pid, {:get_pid, self()})

    receive do
      {:ok, node} ->
        node

      _ ->
        :error

        # code
    end
  end

  defp loop(node, master_pid) do
    receive do
      {:stop} ->
        :ok

      {:get_pid, pid_to_reply} ->

        send(pid_to_reply, {:ok, node})
        loop(node,master_pid)
    after
      10000 ->
        a = check(node)

        case a do
          :dead ->
            send(master_pid, {:dead, self()})

          :alive ->
            loop(node, master_pid)
        end

        # code
    end
  end

  defp check(node) do


    case Node.ping(node) do
      :pang ->
        :dead

      :pong ->
        :alive
    end
  end
end
