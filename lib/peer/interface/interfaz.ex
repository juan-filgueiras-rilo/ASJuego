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

  def init(pidinter, game) do
    pidred = Network.initialize(self())
    Network.set_game_pid(pidred,game)
    menu(pidinter, game, pidred)
  end

  def menu(pidinter, game, pidred) do
    receive do
      {:op, op} ->
        operaciones(op, pidinter, game, pidred)

      {:fightIncoming, data} ->
        IO.puts("Recibida conexion")
        IO.puts("Usted desea jugar? (S o N)")
        inicio_juego(pidinter, game, pidred)
        menu(pidinter, game, pidred)
    end
  end

  def inicio_juego(pidinter, game, pidred) do
    receive do
      {:op, op} -> op_juego(op, pidinter, game, pidred)
    end
  end


  #Recibe es el mensaje del rival tras atacar

  def juego(pidred, pidinter, game) do
    receive do
      {:attack, hechizo} ->
        send(pidinter, :game)
        juego(pidred, pidinter, game)

      {:op, op} ->
        jugada_partida(pidred, pidinter, op, game)
        juego(pidred, pidinter, game)

      :escapar ->
        IO.puts("\n\nEl jugador ha escapado")
        IO.puts("Partida finalizada\n\n")

		#send(node, :end)

      :end ->
        :ok
    end
  end


  def jugada_partida(pidred, pidinter, "1\n", game) do
    IO.puts("Viendo hechizos disponibles...\n")

    nivel = Jugador.getNivel(GameFacade.obtenerJugador(game))
    Utils.mostrarHechizosDetallados(GameFacade.getHechizosDisponibles(game), nivel, 1)
    send(pidinter, :game)
  end

  def jugada_partida(pidred, pidinter, "2\n", game) do
    Utils.mostrarJugador(GameFacade.obtenerJugador(game), 1)
    send(pidinter, :game)
  end

  def jugada_partida(pidred, pidinter, "3\n", game) do
    IO.puts("Viendo datos rival...\n")
	enemigo = GameFacade.obtenerEnemigo(game)
    Utils.mostrarJugador(enemigo, 1)
    send(pidinter, :game)
  end


  def jugada_partida(pidred, pidinter, "4\n", game) do

    IO.puts("Mostrando hechizos...\n")
	nivel = Jugador.getNivel(GameFacade.obtenerJugador(game))
    hechizos = GameFacade.getHechizosDisponibles(game)
    Utils.mostrarHechizosDetallados(hechizos, nivel, 1);
    #IO.puts("Introduzca un número entre 1 y " <> Kernel.inspect(List.length(hechizos)));
    IO.puts("Introduzca 0 para volver atras");

	send pidinter, :hechizo

	receive do
      {:op, "0\n"} -> send pidred, :game
      {:op, op}
        when is_binary(op)
        and op != "0\n"   ->  {opcion, _} = Integer.parse(String.replace(op, "\n", ""));
                              hechizo = accion_hechizo(opcion, hechizos)
							  resultado = GameFacade.usarHechizoPropio(game, hechizo)

							  case resultado do
							    :turnoInvalido -> IO.puts("Espere su turno...\n")
							    :estadoInvalido -> IO.puts("Error: no estas en combate\n")
							    :victoria -> IO.puts("VICTORIAAA")
							    _ ->  IO.puts("Hechizo utilizado!")
								      IO.puts("Espere su turno...\n")
									  send(node, {:recibe, hechizo})
							  end
    end


	#Añadir metodo GameFacade.userHechizoRemoto (game, hechizo) en el recibeS

	#Enviar hechizo tb

  end




  def accion_hechizo(1, [h | _])
  do
    h
  end

  def accion_hechizo(numero, [h | hechizos])
    when is_integer(numero)
    and numero > 1
  do
    accion_hechizo(numero - 1, hechizos)
  end

  def accion_hechizo(numero, [])
    when is_integer(numero)
    and numero > 1
  do
    :numeroInvalido
  end



  def jugada_partida(pidred, pidinter, "5\n", game) do
    IO.puts("Finalizando partida...\n")
    GameFacade.retirarse(game)

	#Enviar mensaje al rival que me retiro
    #send(node, :escapar)
  end

  def jugada_partida(pidred, pidinter, _, _) do
    IO.puts("Opcion erronea..\n")
    send(pidinter, :game)
  end


#eliminar posteriormente el parametro borrar


# Se inicia la partida

  def op_juego("S\n", pidinter, game, pidred) do
    IO.puts("\n\nA jugar\n!")
	
	Network.acceptIncoming(pidred)
	
	
	receive do
		:yes -> send(pidinter, :game)
                juego(pidred, pidinter, game)
				send(pidinter, :menu)
			    menu(pidinter, game, pidred)

		:no -> IO.puts ("No se pudo establecer el combate")
			   send(pidinter, :menu)
			   menu(pidinter, game, pidred)
	end 
  end

  def op_juego("N\n", pidinter, game, pidred) do
	Network.rejectIncoming(pidred)
    #send(node, :no)
    send(pidinter, :menu)
    :ok
  end

  def op_juego(_, pidinter, game, pidred) do
    IO.puts("Opcion erronea")
    send(pidinter, :play)
    inicio_juego(pidinter, game, pidred)
  end

  def operaciones("1\n", pidinter, game, pidred) do
    Network.findGame(pidred)

    receive do
      :playerFound ->
        IO.puts("\n\nA jugar!")
        IO.puts("Espere su turno...")
        juego(pidred, pidinter, game)

      :noGameAvailable ->
        IO.puts("No jugar")
    end

    send(pidinter, :menu)
    menu(pidinter, game, pidred)
  end

  def operaciones("2\n", pidinter, game, pidred) do
	Utils.mostrarJugador(GameFacade.obtenerJugador(game), 1)
    send(pidinter, :menu)
    menu(pidinter, game, pidred)
  end

  def operaciones("3\n", pidinter, game, pidred) do
    Utils.mostrarClases(GameFacade.listarClases(game), 1)
    send(pidinter, :menu)
	menu(pidinter, game, pidred)
  end

  def operaciones("4\n", pidinter, _, _) do
    IO.puts("Juego finalizado\n")
    send(pidinter, :exit)
  end

  def operaciones(_, pidinter, game, pidred) do
    IO.puts("Opcion erronea...\n")
    send(pidinter, :menu)
    menu(pidinter, game, pidred)
  end
end
