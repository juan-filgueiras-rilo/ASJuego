defmodule Main do
    @initial_state %{
        playerData: "./data/PlayerData.json",
        gameData: "./data/GameData.json"
    }
    

    def init() do
        IO.puts("\n\nBIENVENIDO A XXXXXXXX\n\n");
        {:ok, juego} = GameFacade.iniciar(@initial_state.gameData, self());
        
        if File.exists?(@initial_state.playerData) do
            IO.puts("Datos de juego encontrados! Cargando...\n");
            GameFacade.cargar(juego, @initial_state.playerData);
            IO.puts("Carga completada! Los datos del jugador son: \n");
            Utils.mostrarJugador(GameFacade.obtenerJugador(juego), 1);
        else
            GameFacade.crearJugador(juego, crearJugador(juego));
            GameFacade.guardar(juego, @initial_state.playerData);
        end
        Interfaz.inicio(juego)
    end

    def crearJugador(juego) do
        IO.puts("Creando nuevo jugador\n");
        IO.puts("\tNombre: ");
        nombre = IO.gets("") |> String.replace("\n", "");
        IO.puts("\n\n\n");
        IO.puts("La lista de clases disponibles es: ");
        Utils.mostrarClases(GameFacade.listarClases(juego), 1);
        IO.puts("\tSeleccionar clase: ")
        clase = IO.gets("") |> String.replace("\n", "");
        Jugador.constructor(nombre, 1, GameFacade.obtenerClase(juego, clase))
    end
end