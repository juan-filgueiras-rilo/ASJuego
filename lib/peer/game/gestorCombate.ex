defmodule GestorCombate do
  use GenServer

    defp _getHechizo({enfriamientoRestante, hechizo})
    do
        hechizo
    end

    defp _getHechizos([{enfriamientoRestante, hechizo} | enfriamiento], salida)
    do
        _getHechizos(enfriamiento, [hechizo | salida])
    end

    defp _getHechizos([], salida)
    do
        salida
    end

    defp _reducirEnfriamiento([], nuevaLista)
    do  
        nuevaLista
    end

    defp _reducirEnfriamiento([{enfriamientoRestante, hechizo} | hechizos], nuevaLista)
        when enfriamientoRestante > 1
    do
        _reducirEnfriamiento(hechizos, [{enfriamientoRestante - 1, hechizo} | nuevaLista])
    
    end

    defp _reducirEnfriamiento([{1, hechizo} | hechizos], nuevaLista )
    do
        _reducirEnfriamiento(hechizos, nuevaLista)
    end

  defp _getHechizoDeEfecto({duracionRestante, hechizo}) do
    hechizo
  end

  defp _getHechizosDeEfectos([{duracionRestante, hechizo} | efectos], salida) do
    _getHechizosDeEfectos(efectos, [hechizo | salida])
  end

  defp _getHechizosDeEfectos([], salida) do
    salida
  end

  defp _reducirDuracionesEfectos([], nuevaLista) do
    nuevaLista
  end

  defp _reducirDuracionesEfectos([{duracionRestante, hechizo} | hechizos], nuevaLista)
       when duracionRestante > 1 do
    _reducirDuracionesEfectos(hechizos, [{duracionRestante - 1, hechizo} | nuevaLista])
  end

  defp _reducirDuracionesEfectos([{1, hechizo} | hechizos], nuevaLista) do
    _reducirDuracionesEfectos(hechizos, nuevaLista)
  end

  def init({jugador, enemigo, turno}) do
    {:ok, {jugador, enemigo, turno, [], [], [], []}}
  end
  
  def handle_call(:obtenerEnemigo, _from, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}) do
	{:reply, {:ok, enemigo}, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}
  end
  
  
  
  
  def handle_call(
        {:hechizoPropio, hechizo},
        _from,
        {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}
      ) do
    case turno do
      :turnoPropio ->
        if (Enum.any?(enfrPropios, fn {_, x} -> x == hechizo end)) do
          {:reply, :hechizoEnfriando, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}
        else
          enfrPropios = _reducirEnfriamiento([{Hechizo.getEnfriamiento(hechizo), hechizo} | enfrPropios], [])
          efectosEnemigo = [{Hechizo.getDuracion(hechizo), hechizo} | efectosEnemigo]

          {jugador, enemigo} =
            Jugador.aplicarHechizos(jugador, _getHechizosDeEfectos(efectosEnemigo, []), enemigo)

          efectosEnemigo = _reducirDuracionesEfectos(efectosEnemigo, [])

          case Jugador.getVida(enemigo) do
            x when x > 0 ->
              {:reply, :continuar,
              {jugador, enemigo, :turnoEnemigo, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}

            x when x <= 0 ->
              {:stop, {:shutdown, :victoria}, :victoria, {}}
          end
        end
        

      :turnoEnemigo ->
        {:reply, :turnoInvalido, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}
    end
  end

  def handle_call(
        {:hechizoRemoto, hechizo},
        _from,
        {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}
      ) do
    case turno do
      :turnoEnemigo ->
        if (Enum.any?(enfrEnemigos, fn {_, x} -> x == hechizo end)) do
          {:reply, :hechizoEnfriando, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}
        else
          enfrEnemigos = _reducirEnfriamiento([{Hechizo.getEnfriamiento(hechizo), hechizo} | enfrEnemigos], [])
          efectosPropios = [{Hechizo.getDuracion(hechizo), hechizo} | efectosPropios]

          {enemigo, jugador} =
            Jugador.aplicarHechizos(enemigo, _getHechizosDeEfectos(efectosPropios, []), jugador)

          efectosPropios = _reducirDuracionesEfectos(efectosPropios, [])

          case Jugador.getVida(jugador) do
            x when x > 0 ->
              {:reply, :continuar, {jugador, enemigo, :turnoPropio, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}

            x when x <= 0 ->
              {:stop, {:shutdown, :derrota}, :derrota, {}}
          end
        end

      :turnoPropio ->
        {:reply, :turnoInvalido, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigos}}
    end
  end

  def handle_call({:hechizosDisponibles}, _from, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigo})
  do
    hechizos = Clase.getHechizosDisponibles(Jugador.getClase(jugador), Jugador.getNivel(jugador));

    hechizosDisponibles = 
      Enum.filter(hechizos, fn x -> not Enum.any?(enfrPropios, fn {_,b} -> b == x end) end);

    {:reply, hechizosDisponibles, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigo}}


  end

  def handle_call({:getJugador}, _from, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigo})
  do
    {:reply, jugador, {jugador, enemigo, turno, efectosPropios, efectosEnemigo, enfrPropios, enfrEnemigo}}
  end

  def terminate(_, _) do
    # :D
    :normal
  end

  def iniciar(jugador, enemigo, turno) do
    GenServer.start(GestorCombate, {jugador, enemigo, turno})
  end

  def usarHechizoPropio(juego, hechizo)
      when is_tuple(hechizo) and
             is_pid(juego) do
    GenServer.call(juego, {:hechizoPropio, hechizo})
  end
  
  def obtenerEnemigo(juego) do  
	GenServer.call(juego, :obtenerEnemigo)
  end
  
  

  def usarHechizoRemoto(juego, hechizo)
      when is_tuple(hechizo) and
             is_pid(juego) do
    GenServer.call(juego, {:hechizoRemoto, hechizo})
  end

  def getHechizosDisponibles(juego)
    when is_pid(juego)
  do
    GenServer.call(juego, {:hechizosDisponibles});    
  end

  def obtenerJugador(juego)
    when is_pid(juego)
  do
    GenServer.call(juego, {:getJugador});
  end

end
