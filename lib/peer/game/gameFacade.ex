defmodule GameFacade do
    use GenServer


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

    defp buscarClase(nombre, [clase | clases])
    do
        if Clase.getNombre(clase) == nombre do
            clase
        else
            buscarClase(nombre, clases)
        end
    end

    defp buscarClase(nombre, [])
    do
        :not_found
    end



    @impl true
    def init({fileNameClases, pidCallback})
    do

        #{:ok, archivoClases} = File.open(fileNameClases, [:read]);
        {:ok, jsonClases} = File.read(fileNameClases);
        {:ok, jsonClases} = JSON.encode(jsonClases);
        clases = Clase.load(jsonClases);
        
        #File.close(fileNameClases);

        {:ok, {:iniciando, pidCallback, clases}}
    end

    # Crear jugador
    @impl true
    def handle_cast({:crearJugador, jugador}, {:iniciando, pidCallback, clases}) 
    do
        {:noreply, {pidCallback, clases, jugador, {:fueraCombate}}}
    end

    # Cargar jugador
    @impl true
    def handle_cast({:cargarJugador, fileNameJugador}, {:iniciando, pidCallback, clases}) 
    do
        
        {:ok, archivoJugador} = File.open(fileNameJugador, [:read]);
        {:ok, jsonJugador} = IO.read(archivoJugador);
        jugador = Jugador.load(jsonJugador);
        File.close(archivoJugador);

        {:noreply, {pidCallback, clases, jugador, {:fueraCombate}}}

    end

    # Guardar
    @impl true
    def handle_cast({:guardar, fileName}, {callbackIU, clases, jugador, combate})
    do
        jsonJugador = Jugador.save(jugador);

        {:ok, archivo} = File.open(fileName, [:write]);
        IO.write(archivo, jsonJugador);
        File.close(archivo);

        {:noreply, {callbackIU, clases, jugador, combate}}
    end


    # GetJugador
    @impl true
    def handle_call(:getJugador, _from, {callbackIU, clases, jugador, combate})
    do
        {:reply, jugador, {callbackIU, clases, jugador, combate}}
    end

    # GetClass
    def handle_call({:getClass, nombre}, _from, {callbackIU, clases, jugador, combate})
    do
        {:reply, buscarClase(nombre, clases), {callbackIU, clases, jugador, combate}}
    end

    # GetClass
    def handle_call({:getClass, nombre}, _from, {:iniciando, callbackIU, clases})
    do
        {:reply, buscarClase(nombre, clases), {:iniciando, callbackIU, clases}}
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


    # IniciarCombate (primer ACK)
    @impl true
    def handle_call({:ack1Combate, pid, datosEnemigo}, _from, {callbackIU, clases, jugador, {:fueraCombate}})
    do
        {:reply, {self(), jugador}, {callbackIU, clases, jugador, {:combate, pid, datosEnemigo, [], []}}}
    end

    # IniciarCombate (segundo ACK)
    @impl true
    def handle_call({:ack2Combate, pid, datosEnemigo}, _from, {callbackIU, clases, jugador, {:estableciendo}})
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
    def handle_call(:hechizoPropio, hechizo, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}})
    do
        efectosEnemigo = [{Hechizo.getDuracion(hechizo), hechizo} | efectosEnemigo];
        {jugador, datosEnemigo} = Jugador.aplicarHechizos(jugador, getHechizosDeEfectos(efectosEnemigo, []), datosEnemigo);
        efectosEnemigo = reducirDuracionesEfectos(efectosEnemigo, []);

        case Jugador.getVida(datosEnemigo) do
            x when x > 0 -> {:reply, :continuar, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}}}
            x when x <= 0 -> {:reply, :victoria, {callBackIU, clases, jugador, {:fueraCombate}}}
        end
        
    end

    # usarHechizoRemoto
    def handle_cast({:hechizoRemoto, hechizo}, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}})
    do
        efectosPropios = [{Hechizo.getDuracion(hechizo), hechizo} | efectosPropios];
        {datosEnemigo, jugador} = Jugador.aplicarHechizos(datosEnemigo, getHechizosDeEfectos(efectosPropios, []), jugador);
        efectosPropios = reducirDuracionesEfectos(efectosPropios, []);
        
        case Jugador.getVida(jugador) do
            x when x > 0 -> {:reply, :continuar, {callBackIU, clases, jugador, {:combate, pid, datosEnemigo, efectosPropios, efectosEnemigo}}}
            x when x <= 0 -> {:reply, :derrota, {callBackIU, clases, jugador, {:fueraCombate}}}
        end

    end

end