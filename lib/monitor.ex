defmodule Monitor do
  def init(ip_addr, master_pid) do
    spawn(fn -> loop(ip_addr, master_pid) end)
  end

  def get(monitor_pid) do
    
    if Process.alive?(monitor_pid) do
      send(monitor_pid, {:get_pid, self()});
      receive do
        {:ok, ip_addr} ->
          ip_addr
  
        #_ ->
        #  :error
  
          # code
      
      end
    else
      :error
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
      2000 ->
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
      {a,b,c,d} = ip_addr;
      ip_addr = "#{a}.#{b}.#{c}.#{d}";
      {:ok, socket} = Socket.TCP.connect(ip_addr, 8000);
      Socket.Stream.send!(socket,json);
      
      miPid = self();
      pid = spawn(fn -> 
        try do
          {:ok, json} = Socket.Stream.recv(socket);
          send(miPid, {:received, json});
        rescue
          _ -> send(miPid, {:error});
        end
      end);
      :timer.sleep(3000);
      receive do
        
        {:received, json} ->
          {:ok, json} = JSON.decode(json);
          case json["result"] do
            "ok" ->
              :alive
            _ -> :dead
          end
        {:error} -> 
          :dead
        _x-> IO.inspect(_x);
              :dead
        after 1 -> 
          Process.exit(pid, :normal);
          :dead
      end



      
    rescue
      _ -> 
        :dead
    end
  end
end
