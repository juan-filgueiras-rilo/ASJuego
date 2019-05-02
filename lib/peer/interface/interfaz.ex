
defmodule Interfaz do

  def inicio(data) do
	mipid = self()
	pid = spawn(fn -> Interfaz.init(mipid) end)
	IO.puts ("Hola! Bienvenido a xxxxxxxxxxxx\n")
	IO.puts ("Introduzca 1 para buscar rival")
	IO.puts ("Introduzca 2 para mostrar estadisticas")
	IO.puts ("Introduzca 3 para finalizar el juego\n")
	recibir(pid)
  end
	
  def recibir(pid) do
	op = IO.gets("")
	send pid, {:op, op}
	
	receive do
		:menu ->  	IO.puts ("Introduzca 1 para buscar rival")
					IO.puts ("Introduzca 2 para mostrar estadisticas")
					IO.puts ("Introduzca 3 para finalizar el juego\n")
					recibir(pid)
		:exit -> :ok
		{:start, node} -> IO.puts ("holaaaaaa")
		:play -> IO.puts ("Usted desea jugar? (S o N)")
				  recibir(pid)
	end
  end
  
  def init(pid) do
  	Peer.registrar()
	menu(pid)
  end
  
  def menu(pid) do
	receive do
		{:op, op} -> operaciones(op, pid)
		{:start, node} -> IO.puts ("Recibida conexion")
						  IO.puts ("Usted desea jugar? (S o N)")
						  juego(node, pid)
						  menu(pid)
	end
  end
  
  def juego(node, pid) do
    receive do
		{:op, op} -> op_juego(op, node, pid)
	end
  end
  
  def op_juego("S\n", node, pid) do
	IO.puts ("A jugar!")
	IO.puts ("Aqui hay que llamar a la logica del juego")
	IO.puts ("Crear proceso pasando de parametro el pid de la interfaz de usuario")
  end
  
  def op_juego("N\n", node, pid) do
	#send node,  
	send pid, :menu
	:ok
  end
  
  def op_juego(_, node, pid) do
	IO.puts ("Opcion erronea")
	send pid, :play
	juego(pid)
  end
  
  def operaciones("1\n", pid) do
	node = Peer.buscar_rival()
	send(node, {:start, node})
	receive do
		:yes, node -> IO.puts("Jugar")
		:no, node -> IO.puts("No jugar")
	end
	send pid, :menu
	menu(pid)
  end
  
  def operaciones("2\n", pid) do
	IO.puts ("Mostrando estadisticas...\n")
	send pid, :menu
	menu(pid)
  end
  
  def operaciones("3\n", pid) do
	IO.puts ("Juego finalizado\n")
	send pid, :exit
  end
  
  def operaciones("4\n", pid) do
	IO.puts ("Juego finalizado\n")
	send pid, :exit
  end
  
  def operaciones(_, pid) do
	IO.puts ("Opcion erronea...\n")
	send pid, :menu
	menu(pid)
  end
  
end
