defmodule Interfaz do
  def inicio(data) do
    mipid = self()
    pid = spawn(fn -> Interfaz.init(mipid, data) end)
    IO.puts("Hola! Bienvenido a xxxxxxxxxxxx\n")
    IO.puts("Introduzca 1 para iniciar un combate:")
    IO.puts("Introduzca 2 para ver datos del jugador:")
    IO.puts("Introduzca 3 para ver datos de las clases:")
    IO.puts("Introduzca 4 para finalizar el juego\n")
    recibir(pid)
  end

  def recibir(pid) do
    op = IO.gets("")
    send(pid, {:op, op})

    receive do
      :menu ->
        IO.puts("Introduzca 1 para iniciar un combate:")
        IO.puts("Introduzca 2 para ver datos del jugador:")
        IO.puts("Introduzca 3 para ver datos de las clases:")
        IO.puts("Introduzca 4 para finalizar el juego\n")
        recibir(pid)

      :exit ->
        :ok
		
      :play ->
        IO.puts("Usted desea jugar? (S o N)")
        recibir(pid)

      :game ->
        IO.puts("Introduzca 1 para ver hechizos disponibles:")
        IO.puts("Introduzca 2 para ver mis datos:")
        IO.puts("Introduzca 3 para ver datos del rival:")
        IO.puts("Introduzca 4 para utilizar hechizo")
        IO.puts("Introduzca 5 para huir del combate\n")
        recibir(pid)
		
	  :hechizo -> recibir(pid)
		
    end
  end

  def init(pid, game) do
    Peer.registrar()
    menu(pid, game)
  end

  def menu(pid, game) do
    receive do
      {:op, op} ->
        operaciones(op, pid, game)

      {:start, node, enemydata} ->
        IO.puts("Recibida conexion")
        IO.puts("Usted desea jugar? (S o N)")
        inicio_juego(node, pid, game, enemydata)
        menu(pid, game)
    end
  end

  def inicio_juego(node, pid, game, enemydata) do
    receive do
      {:op, op} -> op_juego(op, node, pid, game, enemydata)
    end
  end


  #En el recibe tendrá que ejecutar el hechizo remoto

  def juego(node, pid, game, rival) do
    receive do
      {:recibe, hechizo} ->
		#GameFacade.usarHechizoPropio(game, hechizo)
        send(pid, :game)
        juego(node, pid, game, rival)

      {:op, op} ->
        jugada_partida(node, pid, op, game, rival)
        juego(node, pid, game, rival)

      :escapar ->
        IO.puts("\n\nEl jugador ha escapado")
        IO.puts("Partida finalizada\n\n")
        send(node, :end)

      :end ->
        :ok
    end
  end



  def jugada_partida(_, pid, "1\n", game, rival) do
    IO.puts("Viendo hechizos disponibles...\n")
    nivel = Jugador.getNivel(GameFacade.obtenerJugador(game))
    Utils.mostrarHechizosDetallados(GameFacade.obtenerHechizosDisponibles(game), nivel, 1)
    send(pid, :game)
  end

  def jugada_partida(_, pid, "2\n", game, rival) do
    IO.puts("Viendo datos jugador...\n")
    Utils.mostrarJugador(GameFacade.obtenerJugador(game), 1)
    send(pid, :game)
  end

  def jugada_partida(_, pid, "3\n", game, rival) do
    IO.puts("Viendo datos rival...\n")
	{:ok, enemigo} = GameFacade.obtenerEnemigo(game)
    Utils.mostrarJugador(enemigo, 1)
    send(pid, :game)
  end

  def jugada_partida(node, pid, "4\n", game, rival) do
  
      IO.puts("Mostrando hechizos...\n") 
	

	IO.puts ("1 para hechizo 1")
	IO.puts ("2 para hechizo 2")
	IO.puts ("3 para hechizo 3")
	IO.puts ("4 para hechizo 4")
	IO.puts ("5 para volver atras")
                               
	send pid, :hechizo
	
	receive do
		{:op, op} -> accion_hechizo(op, pid, node)
	end 
	
	
    # AQUI HABRA QUE CURRARSE UNA FORMA DE ELEGIR UN HECHIZO
    #hechizo = :pepe
    #resultado = GameFacade.usarHechizoPropio(game, hechizo)

    #case resultado do
    #  :turnoInvalido -> IO.puts("Espere su turno...\n")
    #  :estadoInvalido -> IO.puts("Error: no estas en combate\n")
    #  :victoria -> IO.puts("VICTORIAAA")
    #  _ -> IO.puts("Hechizo utilizado!")
    #end
	
	
	#Añadir metodo GameFacade.userHechizoRemoto (game, hechizo) en el recibe
	#Enviar hechizo tb

  end
  
  
  
  def accion_hechizo("1\n", pid, node) do
	IO.puts ("Ejecutando hechizo 1... \n\n")
    send(node, {:recibe, hechizo})
  end 
  
  def accion_hechizo("2\n", pid, node) do
    IO.puts ("Ejecutando hechizo 1... \n\n")
    send(node, {:recibe, hechizo})
  end 
  
  def accion_hechizo("3\n", pid, node) do
    IO.puts ("Ejecutando hechizo 1... \n\n")
    send(node, {:recibe, hechizo})
  end 
  
  def accion_hechizo("4\n", pid, node) do
    IO.puts ("Ejecutando hechizo 1... \n\n")
    send(node, {:recibe, hechizo})
  end 
  
  def accion_hechizo("5\n", pid, _) do
	send pid, :game
  end 
  
  def accion_hechizo("5\n", pid, _) do
	IO.puts ("Opcion erronea...\n\n")
	send pid, :game
  end 
  
  

  def jugada_partida(node, _, "5\n", game, rival) do
    IO.puts("Finalizando partida...\n")
    GameFacade.retirarse(game)
    send(node, :escapar)
  end

  def jugada_partida(_, pid, _, _, rival) do
    IO.puts("Opcion erronea..\n")
    send(pid, :game)
  end


#eliminar posteriormente el parametro borrar

  def op_juego("S\n", node, pid, game, {borrar, enemydata}) do
    IO.puts("\n\nA jugar\n!")

    send(node, :yes)
    send(pid, :game)
	
	
    {enemigo, pidRed} = {:pepe, :pepe}
    {borrar2, rival} = GameFacade.ackCombate(game, self(), enemydata)
    
	juego(node, pid, game, rival)
    send(pid, :menu)
    menu(pid, game)
  end

  def op_juego("N\n", node, pid, _, enemydata) do
    #info = Process.info(self())
    #{_, name} = List.keyfind(info, :registered_name, 0)
    send(node, :no)
    send(pid, :menu)
    :ok
  end

  def op_juego(_, node, pid, game, enemydata) do
    IO.puts("Opcion erronea")
    send(pid, :play)
    inicio_juego(node, pid, game, enemydata)
  end

  def operaciones("1\n", pid, game) do
    rivalnode = Peer.buscar_rival()
    info = Process.info(self())
    {_, name} = List.keyfind(info, :registered_name, 0)
    send(rivalnode, {:start, {name, Node.self()}, GameFacade.synCombate(game)})

    receive do
      :yes ->
        IO.puts("\n\nA jugar!")
        IO.puts("Espere su turno...")
        juego(rivalnode, pid, game, "agua")

      :no ->
        IO.puts("No jugar")
    end

    send(pid, :menu)
    menu(pid, game)
  end

  def operaciones("2\n", pid, game) do
	Utils.mostrarJugador(GameFacade.obtenerJugador(game), 1)
    send(pid, :menu)
    menu(pid, game)
  end

  def operaciones("3\n", pid, game) do
    Utils.mostrarClases(GameFacade.listarClases(game), 1)
    send(pid, :menu)
	menu(pid, game)
  end

  def operaciones("4\n", pid, _) do
    IO.puts("Juego finalizado\n")
    send(pid, :exit)
  end

  def operaciones(_, pid, game) do
    IO.puts("Opcion erronea...\n")
    send(pid, :menu)
    menu(pid, game)
  end
end
