defmodule Utils do
    defp getTabs(0, result)
    do
        result
    end
    
    defp getTabs(n, result)
        when is_integer(n)
        and n > 0
    do
        getTabs(n - 1, "\t" <> result)
    end

    defp getTabs(n)
        when is_integer(n)
        and n >= 0
    do
        getTabs(n, "")
    end

    
    def mostrarJugador(jugador, tabs) do
        tabs = getTabs(tabs);
        IO.puts("\n" <> tabs <> "Jugador: " <> Jugador.getNombre(jugador) <> "\n");
        IO.puts(tabs <> "Clase: " <> Clase.getNombre(Jugador.getClase(jugador)) <> "\n");
        IO.puts(tabs <> "Nivel: " <> Kernel.inspect(Jugador.getNivel(jugador)) <> "\n");
        IO.puts(tabs <> "Vida: " <> Kernel.inspect(Jugador.getVida(jugador)) <> "\n\n");
    end

    def mostrarClase(clase, tabs) do
        tabsString = getTabs(tabs);
        IO.puts("\n" <> tabsString <> "Clase: " <> Clase.getNombre(clase) <> "\n");
        IO.puts(tabsString <> "Hechizos: " <> "\n");
        hechizos = Enum.map(Clase.getHechizos(clase), fn x -> Hechizo.getNombre(x) end);
        textoHechizos = Enum.reduce(hechizos, "\n",
            fn (x, acc) ->
                x <> "\n" 
                <> getTabs(tabs + 1)
                <> acc 
        end)
        IO.puts(getTabs(tabs + 1) <> textoHechizos <> "\n");
    end


    def mostrarClases([clase | clases], tabs) 
        when clases != []
    do
        mostrarClase(clase, tabs);
        IO.puts("---------------------------");
        mostrarClases(clases, tabs)
    end

    def mostrarClases([clase], tabs)
    do
        mostrarClase(clase, tabs)
    end

    def mostrarClases([], tabs)
    do
        :ok
    end

    def mostrarHechizo(hechizo, tabs) do
        tabs = getTabs(tabs);
    end
end