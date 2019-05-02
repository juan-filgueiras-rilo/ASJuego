defmodule GestorCombate do
    use GenServer;

    defp _getHechizoDeEfecto({duracionRestante, hechizo})
    do
        hechizo
    end

    defp _getHechizosDeEfectos([{duracionRestante, hechizo} | efectos], salida)
    do
        _getHechizosDeEfectos(efectos, [hechizo | salida])
    end

    defp _getHechizosDeEfectos([], salida)
    do
        salida
    end

    defp _reducirDuracionesEfectos([], nuevaLista)
    do
        nuevaLista
    end

    defp _reducirDuracionesEfectos([{duracionRestante, hechizo} | hechizos], nuevaLista)
        when duracionRestante > 1
    do
        _reducirDuracionesEfectos(hechizos, [{duracionRestante - 1, hechizo} | nuevaLista])
    end

    defp _reducirDuracionesEfectos([{1, hechizo} | hechizos], nuevaLista)
    do
        _reducirDuracionesEfectos(hechizos, nuevaLista)
    end


    def init({jugador, enemigo, turno}) do
        {:ok, {jugador, enemigo, turno, [], []}};
    end

    def handle_call({:hechizoPropio, hechizo}, _from, {jugador, enemigo, turno, efectosPropios, efectosEnemigo}) do
        case turno do
            :turnoPropio -> efectosEnemigo = [{Hechizo.getDuracion(hechizo), hechizo} | efectosEnemigo];
                            {jugador, enemigo} = Jugador.aplicarHechizos(jugador, _getHechizosDeEfectos(efectosEnemigo, []), enemigo);
                            efectosEnemigo = _reducirDuracionesEfectos(efectosEnemigo, []);
                    
                            case Jugador.getVida(enemigo) do
                                x when x > 0 -> {:reply, :continuar, {jugador, enemigo, :turnoEnemigo, efectosPropios, efectosEnemigo}}
                                x when x <= 0 -> {:stop, {:shutdown, :victoria}, :victoria, {}}
                            end
            :turnoEnemigo -> {:reply, :turnoInvalido, {jugador, enemigo, turno, efectosPropios, efectosEnemigo}}
        end
        
    end

    def handle_call({:hechizoRemoto, hechizo}, _from, {jugador, enemigo, turno, efectosPropios, efectosEnemigo}) do
        case turno do
            :turnoEnemigo -> efectosPropios = [{Hechizo.getDuracion(hechizo), hechizo} | efectosPropios];
                            {enemigo, jugador} = Jugador.aplicarHechizos(enemigo, _getHechizosDeEfectos(efectosPropios, []), jugador);
                            efectosPropios = _reducirDuracionesEfectos(efectosPropios, []);
                    
                            case Jugador.getVida(jugador) do
                                x when x > 0 -> {:reply, :continuar, {jugador, enemigo, :turnoPropio, efectosPropios, efectosEnemigo}}
                                x when x <= 0 -> {:stop, {:shutdown, :derrota}, :derrota, {}}
                            end
            :turnoPropio -> {:reply, :turnoInvalido, {jugador, enemigo, turno, efectosPropios, efectosEnemigo}}
        end
        
    end

    def terminate(_, _) do
        :normal # :D
    end

    def iniciar(jugador, enemigo, turno) do
        GenServer.start_link(GestorCombate, {jugador, enemigo, turno})
    end

    def usarHechizoPropio(juego, hechizo)
        when is_tuple(hechizo)
        and is_pid(juego)
    do
        GenServer.call(juego, {:hechizoPropio, hechizo})
    end

    def usarHechizoRemoto(juego, hechizo)
        when is_tuple(hechizo)
        and is_pid(juego)
    do
        GenServer.call(juego, {:hechizoRemoto, hechizo})  
    end
end
