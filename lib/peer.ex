defmodule Peer do


def registrar() do
	mensaje_registrar(GenServer.call({:super,:"super@192.168.43.142"}, {:registrar,Node.self()}, 5000))
end

def mensaje_registrar(:ok) do
	IO.puts("Registro satisfatorio")
end

def mensaje_registrar(_) do
	IO.puts("Fallo en el registro, intentelo de nuevo")
end

def buscar_rival() do
  resultado_buscar(GenServer.call({:super,:"super@192.168.43.142"}, :pedir_lista, 5000))
end

def resultado_buscar(:ok, lista) do
	Enum.random(lista)
end

def resultado_buscar(_) do
	IO.puts("Fallo en la conexion con el superpeer, intentelo de nuevo")
end 


def conectarse(pid) do


end








end
