
defmodule Interfaz do

  def inicio(data) do
	mipid = self()
	pid = spawn(fn -> Interfaz.init(mipid, data) end)
	IO.puts ("Hola! Bienvenido a xxxxxxxxxxxx\n")
	IO.puts ("Introduzca 1 para iniciar un combate:")
	IO.puts ("Introduzca 2 para ver datos del jugador:")
	IO.puts ("Introduzca 3 para ver datos de las clases:")
	IO.puts ("Introduzca 4 para finalizar el juego\n")
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
  
  def init(pid, game) do
  	Peer.registrar()
		menu(pid, game)
  end
  
  def menu(pid, game) do
	receive do
		{:op, op} -> operaciones(op, pid, game)
		{:start, node} -> IO.puts ("Recibida conexion")
						  IO.puts ("Usted desea jugar? (S o N)")
						  inicio_juego(node, pid, game)
						  menu(pid, game)
	end
  end
  
  def inicio_juego(node, pid, game) do
    receive do
		{:op, op} -> op_juego(op, node, pid, game)
	end
  end
  
  
  
  def juego(node, pid, game) do
	receive do
		{:recibe, pid2} -> send pid, :game
						  juego(node, pid, game)
		{:op, op} -> jugada_partida(node, pid, op, game)
				     juego(node, pid, game)
		:escapar -> IO.puts ("\n\nEl jugador ha escapado")
					IO.puts ("Partida finalizada\n\n")
					send(node, :end)
		:end -> :ok				
	end
  end
  
  def jugada_partida(node, pid, "1\n", game) do
	IO.puts ("Viendo hechizos disponibles...\n");
	nivel = Jugador.getNivel(GameFacade.obtenerJugador(game))
	Utils.mostrarHechizosDetallados(GameFacade.obtenerHechizosDisponibles(game), nivel, 1)
	send pid, :game
  end
  
  def jugada_partida(node, pid, "2\n", game) do
	IO.puts ("Viendo datos jugador...\n");
	Utils.mostrarJugador(GameFacade.obtenerJugador(game),1)
	send pid, :game
  end
  
  def jugada_partida(node, pid, "3\n", game) do
	IO.puts ("Viendo datos rival...\n");
	Utils.mostrarJugador(GameFacade.obtenerEnemigo(game), 1)
	send pid, :game
  end
  
  
  def jugada_partida(node, pid, "4\n", game) do
	IO.puts ("Usando hechizo...\n");
	hechizo = :pepe; #AQUI HABRA QUE CURRARSE UNA FORMA DE ELEGIR UN HECHIZO
	resultado = GameFacade.usarHechizoPropio(game, hechizo)
	case resultado do
		:turnoInvalido -> IO.puts ("Espere su turno...\n");
		:estadoInvalido -> IO.puts("Error: no estas en combate\n");
		:victoria -> IO.puts("VICTORIAAA");
		_ -> IO.puts("Hechizo utilizado!");
	end
	
	send(node, {:recibe, pid}) 
  end
  
  def jugada_partida(node, pid, "5\n", game) do
	IO.puts ("Finalizando partida...\n");
	GameFacade.retirarse(game);
	send(node, :escapar)
  end
  
  def jugada_partida(node, pid, _, game) do
	IO.puts ("Opcion erronea..\n");
	send pid, :game
  end
  
  

  def op_juego("S\n", node, pid, game) do
	IO.puts ("\n\nA jugar\n!")

	send(node, :yes) 
	send pid, :game
	# AQUI SE LE ENVIA LA ORDEN POR RED AL OTRO GAMEFACADE DE INICIAR EL JUEGO, NO SE COMO
	# O TAMPOCO SE SI NOS ESTAN INICIANDO COMBATE POR FUERA. ASUMO QUE NOS LO INICIAN, Y NOS
	# MANDAN ESOS DOS DATOS.
	{enemigo, pidRed} = {:pepe, :pepe}
	GameFacade.ackCombate(game, pidRed, enemigo)


	juego(node, pid, game)
	send pid, :menu
	menu(pid, game)
  end
  
  def op_juego("N\n", node, pid, game) do
	info = Process.info(self())
	{_, name} = List.keyfind(info, :registered_name, 0)
	send(node, :no) 
	send pid, :menu
	:ok
  end
  
  def op_juego(_, node, pid, game) do
	IO.puts ("Opcion erronea")
	send pid, :play
	inicio_juego(node, pid, game)
  end
  
  def operaciones("1\n", pid, game) do
	rivalnode = Peer.buscar_rival()
	info = Process.info(self())
	{_, name} = List.keyfind(info, :registered_name, 0)
	send(rivalnode, {:start, {name, Node.self()}})
	receive do
		:yes -> IO.puts("\n\nA jugar!")
					    IO.puts ("Espere su turno...")
						juego(rivalnode, pid, game)
		:no -> IO.puts("No jugar")
	end
	send pid, :menu
	menu(pid, game)
  end
  
  def operaciones("2\n", pid, game) do
	IO.puts ("Mostrando datos...\n")
	
	
	send pid, :menu
	menu(pid, game)
  end
  
  def operaciones("3\n", pid, game) do
	IO.puts ("Mostrando clases...\n")
	Utils.mostrarClases(GameFacade.listarClases(game))
	send pid, :exit
  end
  
  def operaciones("4\n", pid, game) do
	IO.puts ("Juego finalizado\n")
	send pid, :exit
  end
  
  def operaciones(_, pid, game) do
	IO.puts ("Opcion erronea...\n")
	send pid, :menu
	menu(pid, game)
  end
  
end
