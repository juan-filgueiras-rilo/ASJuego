defmodule GameFacade do
    use GenServer


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

    defp _buscarClase(nombre, [clase | clases])
    do
        if Clase.getNombre(clase) == nombre do
            clase
        else
            _buscarClase(nombre, clases)
        end
    end

    defp _buscarClase(nombre, [])
    do
        :not_found
    end



    @impl true
    def init({fileNameClases, pidCallback})
    do
        try do
            {:ok, jsonClases} = File.read(fileNameClases);
            {:ok, jsonClases} = JSON.decode(jsonClases);
            clases = Enum.map(jsonClases["clases"], fn x -> Clase.load(x) end)
            {:ok, {:iniciando, pidCallback, clases}}
        rescue
            _ -> {:stop, :errorLoading}
        end
    end

    # Crear jugador
    @impl true
    def handle_cast({:crearJugador, jugador}, {:iniciando, pidCallback, clases}) 
    do
        {:noreply, {pidCallback, clases, jugador, {:fueraCombate}}}
    end

    # Cargar jugador
    @impl true
    def handle_call({:cargarJugador, fileNameJugador}, _from, {:iniciando, pidCallback, clases}) 
    do
        try do
            {:ok, jsonJugador} = File.read(fileNameJugador);
            {:ok, jsonJugador} = JSON.decode(jsonJugador);

            jsonJugador = %{
                "jugador" => %{
                    "nombre" => jsonJugador["jugador"]["nombre"],
                    "nivel" => jsonJugador["jugador"]["nivel"],
                    "vida" => jsonJugador["jugador"]["vida"],
                    "clase" => Clase.save(_buscarClase(jsonJugador["jugador"]["clase"], clases))
                }
            }
            jugador = Jugador.load(jsonJugador["jugador"]);
            {:reply, :ok, {pidCallback, clases, jugador, {:fueraCombate}}}
        rescue
            _ -> {:reply, :error, {:iniciando, pidCallback, clases}}
        end

    end

    # Guardar
    @impl true
    def handle_call({:guardar, fileName}, _from, {callbackIU, clases, jugador, combate})
    do
        try do
            datosJugador = Jugador.saveWithClassName(jugador);
            datosJugador = %{
                "Jugador" => datosJugador
            };
            {:ok, jsonJugador} = JSON.encode(datosJugador);
            {:ok, archivo} = File.open(fileName, [:write]);
            IO.write(archivo, jsonJugador);
            File.close(archivo);
            {:reply, :ok, {callbackIU, clases, jugador, combate}}
        rescue
            _ -> {:reply, :error, {callbackIU, clases, jugador, combate}}
        end
    end


    # GetJugador
    @impl true
    def handle_call(:getJugador, _from, {callbackIU, clases, jugador, combate})
    do
        {:reply, jugador, {callbackIU, clases, jugador, combate}}
    end

    @impl true
    def handle_call(:getEstado, _from, gameState)
    do
        case gameState do
            {_, _, _, {:fueraCombate}} -> {:reply, :fueraCombate, gameState}
            {_, _, _, {:estableciendo}} -> {:reply, :estableciendo, gameState}
            {_, _, _, {:combate, _, _, _, _}} -> {:reply, :combate, gameState}
            _ -> {:reply, :iniciando, gameState}
        end
    end

    # GetClass
    def handle_call({:getClass, nombre}, _from, {callbackIU, clases, jugador, combate})
    do
        {:reply, _buscarClase(nombre, clases), {callbackIU, clases, jugador, combate}}
    end

    # GetClass
    def handle_call({:getClass, nombre}, _from, {:iniciando, callbackIU, clases})
    do
        {:reply, _buscarClase(nombre, clases), {:iniciando, callbackIU, clases}}
    end

    # ListClasses
    def handle_call(:listClasses, _from, {callbackIU, clases, jugador, combate})
    do
        {:reply, clases, {callbackIU, clases, jugador, combate}}
    end

    # ListClasses
    def handle_call(:listClasses, _from, {:iniciando, callbackIU, clases})
    do
        {:reply, clases, {:iniciando, callbackIU, clases}}
    end

    
    # IniciarCombate (syn)
    @impl true
    def handle_call(:synCombate, _from, {callbackIU, clases, jugador, {:fueraCombate}})
    do
        {:reply, {self(), jugador}, {callbackIU, clases, jugador, {:estableciendo}}}
    end


    # IniciarCombate (ACK)
    @impl true
    def handle_call({:ackCombate, pid, datosEnemigo}, _from, {callbackIU, clases, jugador, {_}})
    do
        {:reply, {self(), jugador}, {callbackIU, clases, jugador, {:combate, pid, datosEnemigo, [], []}}}
    end

    # Retirarse
    @impl true
    def handle_cast(:retirarse, {callBackIU, clases, jugador, {:combate, _, _, _, _}})
    do
        {:noreply, {callBackIU, clases, jugador, {:fueraCombate}}}
    end


    # usarHechizoPropio
    def handle_call({:hechizoPropio, hechizo}, _from, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}})
    do
        efectosEnemigo = [{Hechizo.getDuracion(hechizo), hechizo} | efectosEnemigo];
        {jugador, datosEnemigo} = Jugador.aplicarHechizos(jugador, _getHechizosDeEfectos(efectosEnemigo, []), datosEnemigo);
        efectosEnemigo = _reducirDuracionesEfectos(efectosEnemigo, []);

        case Jugador.getVida(datosEnemigo) do
            x when x > 0 -> {:reply, :continuar, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}}}
            x when x <= 0 -> {:reply, :victoria, {callBackIU, clases, Jugador.subirNivel(jugador), {:fueraCombate}}}
        end
        
    end

    # usarHechizoRemoto
    def handle_call({:hechizoRemoto, hechizo}, _from, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}})
    do
        efectosPropios = [{Hechizo.getDuracion(hechizo), hechizo} | efectosPropios];
        {datosEnemigo, jugador} = Jugador.aplicarHechizos(datosEnemigo, _getHechizosDeEfectos(efectosPropios, []), jugador);
        efectosPropios = _reducirDuracionesEfectos(efectosPropios, []);
        
        case Jugador.getVida(jugador) do
            x when x > 0 -> {:reply, :continuar, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}}}
            x when x <= 0 -> {:reply, :derrota, {callBackIU, clases, jugador, {:fueraCombate}}}
        end

    end


    def iniciar(fileNameClasses, pidCallback)
        when is_binary(fileNameClasses)
        and is_pid(pidCallback)
    do
        GenServer.start_link(GameFacade, {fileNameClasses, pidCallback})
    end

    def cargar(juego, fileNamePlayer)
        when is_binary(fileNamePlayer)
        and is_pid(juego)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :iniciando -> GenServer.call(juego, {:cargarJugador, fileNamePlayer})
            _ -> :estadoInvalido
        end
    end

    def crearJugador(juego, jugador)
        when is_pid(juego)
        and is_tuple(jugador)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :iniciando -> GenServer.cast(juego, {:crearJugador, jugador})
            _ -> :estadoInvalido
        end
    end

    def guardar(juego, fileName)
        when is_pid(juego)
        and is_binary(fileName)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :iniciando -> :estadoInvalido
            _ -> GenServer.call(juego, {:guardar, fileName})
        end
    end

    def listarClases(juego)
        when is_pid(juego)
    do
        GenServer.call(juego, :listClasses)
    end

    def obtenerClase(juego, clase)
        when is_pid(juego)
        and is_binary(clase)
    do
        GenServer.call(juego, {:getClass, clase})
    end

    def obtenerJugador(juego)
        when is_pid(juego)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :iniciando -> :estadoInvalido
            _ -> GenServer.call(juego, :getJugador)
        end
    end

    def synCombate(juego)
        when is_pid(juego)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :fueraCombate -> GenServer.call(juego, :synCombate)
            _ -> :estadoInvalido
        end
    end

    def ackCombate(juego, pidRed, datosEnemigo)
        when is_pid(juego)
        and is_pid(pidRed)
        and is_tuple(datosEnemigo)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :fueraCombate -> GenServer.call(juego, {:ackCombate, pidRed, datosEnemigo})
            :estableciendo  -> GenServer.call(juego, {:ackCombate, pidRed, datosEnemigo})
            _ -> :estadoInvalido
        end 
        
    end

    def retirarse(juego)
        when is_pid(juego)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :combate -> GenServer.cast(juego, :retirarse);
                        :ok
            _ -> :estadoInvalido
        end 
    end

    def usarHechizoPropio(juego, hechizo)
        when is_tuple(hechizo)
        and is_pid(juego)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :combate -> GenServer.call(juego, {:hechizoPropio, hechizo})
            _ -> :estadoInvalido
        end 
    end

    def usarHechizoRemoto(juego, hechizo)
        when is_tuple(hechizo)
        and is_pid(juego)
    do
        estado = GenServer.call(juego, :getEstado);
        case estado do
            :combate -> GenServer.call(juego, {:hechizoRemoto, hechizo})
            _ -> :estadoInvalido
        end    
    end
end