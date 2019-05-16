defmodule Interfaz do
  def inicio(data) do
    mipid = self()
    pid = spawn(fn -> Interfaz.init(mipid, data) end)
	IO.puts("\t|--------------------|")
    IO.puts("\t|   Adventure Game   |")
	IO.puts("\t|--------------------|\n\n")
    IO.puts("Introduzca 1 para iniciar un combate:")
    IO.puts("Introduzca 2 para ver datos del jugador:")
    IO.puts("Introduzca 3 para ver datos de las clases:")
    IO.puts("Introduzca 4 para finalizar el juego\n")
    interaccion_usuario(pid)
  end

  def interaccion_usuario(pid) do
    op = IO.gets("")
    send(pid, {:op, op})

    receive do
      :menu ->
        IO.puts("Introduzca 1 para iniciar un combate:")
        IO.puts("Introduzca 2 para ver datos del jugador:")
        IO.puts("Introduzca 3 para ver datos de las clases:")
        IO.puts("Introduzca 4 para finalizar el juego\n")
        interaccion_usuario(pid)

      :exit ->
        :ok

      :play ->
        IO.puts("Usted desea jugar? (S o N)")
        interaccion_usuario(pid)

      :game ->
        IO.puts("Introduzca 1 para ver hechizos disponibles:")
        IO.puts("Introduzca 2 para ver mis datos:")
        IO.puts("Introduzca 3 para ver datos del rival:")
        IO.puts("Introduzca 4 para utilizar hechizo")
        interaccion_usuario(pid)


	  :hechizo -> interaccion_usuario(pid)

    end
  end

  def init(pidinter, game) do
    GameFacade.setUICallback(game, self());
    pidred = Network.initialize(self())
    Network.set_game_pid(pidred,game)
    menu(pidinter, game, pidred)
  end

  def menu(pidinter, game, pidred) do
    receive do
      {:op, op} ->
        operaciones(op, pidinter, game, pidred)

      {:fightIncoming, _} ->
        IO.puts("\nUn jugador quiere jugar contra ti.")
        IO.puts("Usted desea jugar? (Introduzca S o N)")
        inicio_juego(pidinter, game, pidred)
		send(pidinter, :menu)
        menu(pidinter, game, pidred)
    end
  end

  def inicio_juego(pidinter, game, pidred) do
    receive do
      {:op, op} -> op_juego(op, pidinter, game, pidred)
    end
  end


  #Recibe es el mensaje del rival tras atacar

  def juego(pidinter, game) do
    receive do
      {:attack, _} ->
        send(pidinter, :game)
        juego(pidinter, game)

      {:op, op} ->
        jugada_partida(pidinter, op, game)
        juego(pidinter, game)

      :escapar ->
        IO.puts("\n\nEl jugador ha escapado")
        IO.puts("Partida finalizada\n\n")
		
      :end ->
        :ok
		
      :derrota -> :ok
    end
  end


  def jugada_partida(pidinter, "1\n", game) do
    IO.puts ("\n\Hechizos disponibles:\n")

    nivel = Jugador.getNivel(GameFacade.obtenerJugador(game))
    Utils.mostrarHechizosDetallados(GameFacade.getHechizosDisponibles(game), nivel, 1)
    send(pidinter, :game)
  end

  def jugada_partida(pidinter, "2\n", game) do
	IO.puts ("\n\nDatos del jugador:\n")
    Utils.mostrarJugador(GameFacade.obtenerJugador(game), 1)
    send(pidinter, :game)
  end

  def jugada_partida(pidinter, "3\n", game) do
    IO.puts ("\n\nDatos del rival:\n")
	enemigo = GameFacade.obtenerEnemigo(game)
    Utils.mostrarJugador(enemigo, 1)
    send(pidinter, :game)
  end


  def jugada_partida(pidinter, "4\n", game) do

    IO.puts("Mostrando hechizos...\n")
	  nivel = Jugador.getNivel(GameFacade.obtenerJugador(game))
    hechizos = GameFacade.getHechizosDisponibles(game)
    Utils.mostrarHechizosDetallados(hechizos, nivel, 1);
    #IO.puts("Introduzca un número entre 1 y " <> Kernel.inspect(List.length(hechizos)));
    IO.puts("Introduzca 0 para volver atras");

	send pidinter, :hechizo

	receive do
      {:op, "0\n"} -> send(pidinter, :game)
      {:op, op}
        when is_binary(op)
        and op != "0\n"   ->  {opcion, _} = Integer.parse(String.replace(op, "\n", ""));
                              hechizo = accion_hechizo(opcion, hechizos)
							  resultado = GameFacade.usarHechizoPropio(game, hechizo)
							  
							  IO.inspect(resultado)

							  case resultado do
							    :victoria -> IO.puts("Enhorabuena, has ganado")
											 pid = self()
											 spawn(fn -> Interfaz.mensaje_propio(pid) end)
							    _ ->  IO.puts("Hechizo utilizado. Espere su turno\n")
							  end
    end

  end
  
    def jugada_partida(pidinter, _, _) do
    IO.puts("Opcion erronea..\n")
    send(pidinter, :game)
  end
  
  
  def mensaje_propio(pid) do
	send(pid, :end)
  end




  def accion_hechizo(1, [h | _])
  do
    h
  end

  def accion_hechizo(numero, [_ | hechizos])
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




#eliminar posteriormente el parametro borrar


# Se inicia la partida

  def op_juego("S\n", pidinter, game, pidred) do
	Network.acceptIncoming(pidred)
	
	
	receive do
		:yes -> 
				IO.puts ("\nPartida iniciada!\n")
				send(pidinter, :game)
                juego(pidinter, game)
				send(pidinter, :menu)
			    menu(pidinter, game, pidred)

		:no -> IO.puts ("\nNo se pudo establecer el combate.\n")
			   send(pidinter, :menu)
			   menu(pidinter, game, pidred)
	end 
  end

  def op_juego("N\n", pidinter, _, pidred) do
	Network.rejectIncoming(pidred)
	IO.puts ("\nPartida rechazada.\n")
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
	IO.puts ("\nBuscando rival. Espere un momento.")

    receive do
      :playerFound ->
        IO.puts("\nPartida iniciada!")
		IO.puts("\nEl oponente rival empezara la partida. Espere su turno.")
        juego(pidinter, game)

      :noGameAvailable ->
        IO.puts("\nOponente no encontrado. Vuelva a intentarlo.\n")
    end

    send(pidinter, :menu)
    menu(pidinter, game, pidred)
  end

  def operaciones("2\n", pidinter, game, pidred) do
	IO.puts ("\n\nDatos del jugador:\n")
	Utils.mostrarJugador(GameFacade.obtenerJugador(game), 1)
    send(pidinter, :menu)
    menu(pidinter, game, pidred)
  end

  def operaciones("3\n", pidinter, game, pidred) do
    IO.puts ("\n\nDatos de las clases:\n")
    Utils.mostrarClases(GameFacade.listarClases(game), 1)
    send(pidinter, :menu)
	menu(pidinter, game, pidred)
  end

  def operaciones("4\n", pidinter, _, _) do
    IO.puts("\nJuego finalizado\n")
    send(pidinter, :exit)
  end

  def operaciones(_, pidinter, game, pidred) do
    IO.puts("\n\nOpcion erronea. Vuelva a intentarlo\n\n")
    send(pidinter, :menu)
    menu(pidinter, game, pidred)
  end
end
