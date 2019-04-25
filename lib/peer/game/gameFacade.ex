defmodule GameFacade do

#------------------------------------
# ESTA ZONA CONTIENE METODOS LOCALES
#------------------------------------

    def constructor(fileName, pidCallback)
        when is_binary(fileName)
    do
        # Cargamos la información del jugador, de las clases y sus hechizos y
        # del mundo (si esta disponible). En caso de que el mundo no lo este,
        # usariamos el metodo generarMundo.
        :todo
    end

    def guardar(fileName, jugador)
    do
        # Guardamos la partida. Debemos recibir el jugador, ya que puede ser que
        # no lo tengamos en este mundo.
    end


    def getJugador(gameState)
    do
        #Devolvemos una referencia al jugador, aunque es de solo lectura
        case gameState do
            {callBackIU, clases, jugador, datosEnemigo} -> jugador
            _ -> :error
        end
    end

    def iniciarCombate(gameState, :synCombate)
    do
        #Comenzamos el proceso de iniciar combate
        case gameState do
            {callBackIU, clases, jugador, {:fueraCombate}} -> 
                estado = {callBackIU, clases, jugador, {:estableciendo}};
                {:ok, self(), jugador}
            _ -> :error
        end
    end

    def iniciarCombate(gameState, :ack1Combate, pid, datosEnemigo)
    do
        # Inicia un combate recibiendo el pid para comunicar el estado,
        # y devuelve mi pid para poder recibir informacion del combate.
        case gameState do
            {callBackIU, clases, jugador, {:fueraCombate}} -> 
                estado = {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, [], []}};
                {:ok, self(), jugador}
            _ -> :error
        end
    end

    def iniciarCombate(gameState, :ack2Combate, pid, datosEnemigo)
    do
        # Inicia un combate pasando el pid del peer2 para poder comunicar el
        # estado.
        case gameState do
            {callBackIU, clases, jugador, {:estableciendo}} -> 
                estado = {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, [], []}};
                :ok
            _ -> :error
        end
    end



    def retirarse(gameState)
    do
        # Te retiras del combate
        case gameState do
            {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}} -> 
                estado = {callBackIU, clases, jugador, {:fueraCombate}};
                :ok
            _ -> :error
        end
    end

    defp getHechizoDeEfecto({duracionRestante, hechizo})
    do
        hechizo
    end

    defp getHechizosDeEfectos([{duracionRestante, hechizo} | efectos], salida)
    do
        getHechizosDeEfectos(efectos, [hechizo | salida])
    end

    defp getHechizosDeEfectos([], salida)
    do
        salida
    end

    defp reducirDuracionesEfectos([], nuevaLista)
    do
        nuevaLista
    end

    defp reducirDuracionesEfectos([{duracionRestante, hechizo} | hechizos], nuevaLista)
        when duracionRestante > 1
    do
        reducirDuracionesEfectos(hechizos, [{duracionRestante - 1, hechizo} | nuevaLista])
    end

    defp reducirDuracionesEfectos([{1, hechizo} | hechizos], nuevaLista)
    do
        reducirDuracionesEfectos(hechizos, nuevaLista)
    end

    def usarHechizoPropio(gameState, hechizo)
    do
        # Usas un hechizo propio, y actualiza el estado aplicando los efectos del enemigo.
        case gameState do
            {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}} -> 
                
                efectosEnemigo = [{Hechizo.getDuracion(hechizo), hechizo} | efectosEnemigo];
                {jugador, datosEnemigo} = Jugador.aplicarHechizos(jugador, getHechizosDeEfectos(efectosEnemigo, []), datosEnemigo);
                
                efectosEnemigo = reducirDuracionesEfectos(efectosEnemigo, []);
                
                estado = {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}};
                
            _ -> :error
        end
    end

    def usarHechizoRemoto(gameState, hechizo)
    do
        # Usas un hechizo propio, y actualiza el estado aplicando los efectos del enemigo.
        case gameState do
            {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}} -> 
                
                efectosPropios = [{Hechizo.getDuracion(hechizo), hechizo} | efectosPropios];
                {datosEnemigo, jugador} = Jugador.aplicarHechizos(datosEnemigo, getHechizosDeEfectos(efectosPropios, []), jugador);
                
                efectosPropios = reducirDuracionesEfectos(efectosPropios, []);
                
                estado = {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}};
                
            _ -> :error
        end
    end

end