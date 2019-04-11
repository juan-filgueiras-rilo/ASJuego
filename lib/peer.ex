defmodule Peer do




def registrar() do
  case GenServer.call({:super,:"super@192.168.43.142"}, {:registrar,Node.self()}, 5000) do
    :ok->IO.puts("Registro satisfatorio")
    _-> IO.puts("Fallo en el registro, intentelo de nuevo")
  end

end


def buscar_rival() do

  case GenServer.call({:super,:"super@192.168.43.142"}, :pedir_lista, 5000) do
    {:ok,lista}->Enum.random(lista)  #Seleciono aleatoriamente un dos peers que me devolve o superPeer
     _-> IO.puts("Fallo en la conexion con el superpeer, intentelo de nuevo")
  end

end


def conectarse(pid) do


end








end
