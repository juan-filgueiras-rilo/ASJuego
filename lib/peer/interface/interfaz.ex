
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
		:menu ->  	IO.puts ("Introduzca 1 para iniciar un combate:")
					IO.puts ("Introduzca 2 para ver datos del jugador:")
					IO.puts ("Introduzca 3 para ver datos de las clases:")
					IO.puts ("Introduzca 4 para finalizar el juego\n")
					recibir(pid)
		:exit -> :ok
		{:start, node} -> IO.puts ("holaaaaaa")
		:play -> IO.puts ("Usted desea jugar? (S o N)")
				  recibir(pid)
		:game ->    IO.puts ("Introduzca 1 para ver hechizos disponibles:")
					IO.puts ("Introduzca 2 para ver mis datos:")
					IO.puts ("Introduzca 3 para ver datos del rival:")
					IO.puts ("Introduzca 4 para utilizar hechizo")
					IO.puts ("Introduzca 5 para huir del combate\n")
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
						  inicio_juego(node, pid)
						  menu(pid)
	end
  end
  
  def inicio_juego(node, pid) do
    receive do
		{:op, op} -> op_juego(op, node, pid)
	end
  end
  
  
  
  def juego(node, pid) do
	receive do
		{:recibe, pid2} -> IO.inspect(self()) 
						send pid, :game
				juego(node, pid)
		{:op, op} -> IO.puts ("ESTO LO RECIBE")
					jugada_partida(node, pid, op)
				     juego(node, pid)
	end
  end
  
  def jugada_partida(node, pid, "1\n") do
	IO.puts ("Viendo hechizos disponibles...\n");
	send pid, :game
  end
  
  def jugada_partida(node, pid, "2\n") do
	IO.puts ("Viendo datos jugador...\n");
	send pid, :game
  end
  
  def jugada_partida(node, pid, "3\n") do
	IO.puts ("Viendo datos rival...\n");
	send pid, :game
  end
  
  
  def jugada_partida(node, pid, "4\n") do
	IO.puts ("Usando hechizo...\n");
	send(node, {:recibe, pid}) 
  end
  
  def jugada_partida(node, pid, "5\n") do
	IO.puts ("Finalizando partida...\n");
  end
  
  def jugada_partida(node, pid, _) do
	IO.puts ("Opcion erronea..\n");
	send pid, :game
  end
  
  

  def op_juego("S\n", node, pid) do
	IO.puts ("A jugar!")
	send(node, :yes) 
	send pid, :game
	juego(node, pid)
  end
  
  def op_juego("N\n", node, pid) do
	info = Process.info(self())
	{_, name} = List.keyfind(info, :registered_name, 0)
	send(node, {:no, {name, Node.self()}}) 
	send pid, :menu
	:ok
  end
  
  def op_juego(_, node, pid) do
	IO.puts ("Opcion erronea")
	send pid, :play
	inicio_juego(node, pid)
  end
  
  def operaciones("1\n", pid) do
	rivalnode = Peer.buscar_rival()
	info = Process.info(self())
	{_, name} = List.keyfind(info, :registered_name, 0)
	send(rivalnode, {:start, {name, Node.self()}})
	receive do
		:yes -> IO.puts("A jugar!")
					    IO.puts ("Esperando tu turno...")
						juego(rivalnode, pid)
		{:no, node} -> IO.puts("No jugar")
	end
	send pid, :menu
	menu(pid)
  end
  
  def operaciones("2\n", pid) do
	IO.puts ("Mostrando datos...\n")
	send pid, :menu
	menu(pid)
  end
  
  def operaciones("3\n", pid) do
	IO.puts ("Mostrando clases...\n")
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
