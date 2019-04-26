defmodule Jugador do
    use Guardable

    def constructor(nombre, nivel, clase)
        when is_integer(nivel)
        and is_binary(nombre)
    do
        {nombre, nivel, clase, Clase.getVidaMax(clase, nivel)}
    end

    def constructor(nombre, nivel, clase, vida)
    do
        {nombre, nivel, clase, vida}
    end

    def load(datos)
    do
        {
            datos["nombre"],
            datos["nivel"],
            Clase.load(datos["clase"]),
            datos["vida"]
        }
    end

    def saveWithClassName({nombre, nivel, clase, vida})
    do
        %{
            "nombre" => nombre,
            "nivel" => nivel,
            "clase" => Clase.getNombre(clase),
            "vida" => vida
        }
    end

    def save({nombre, nivel ,clase, vida})
    do
        %{
            "nombre" => nombre,
            "nivel" => nivel,
            "clase" => Clase.save(clase),
            "vida" => vida
        }
    end

    def getHechizosDisponibles({_, nivel, clase, _})
    do
        Clase.getHechizosDisponibles(clase, nivel)
    end

    def getVida({_, _, _, vida})
    do
        vida
    end

    def aplicarHechizo({nombrePropio, nivelPropio, clasePropia, vidaPropia}, hechizo, {nombreEnemigo, nivelEnemigo, claseEnemigo, vidaEnemigo})
    do
        # Utilizo un hechizo y devuelvo el par con los datos mios y del enemigo actualizados.
        fuerza = Hechizo.getFuerza(hechizo, nivelEnemigo);
        case Hechizo.getTipo(hechizo) do
            "DMG" -> {{nombrePropio, nivelPropio, clasePropia, vidaPropia}, {nombreEnemigo, nivelEnemigo, claseEnemigo, vidaEnemigo - fuerza}}
            "CUR" -> {{nombrePropio, nivelPropio, clasePropia, vidaPropia + fuerza}, {nombreEnemigo, nivelEnemigo, claseEnemigo, vidaEnemigo}}
            "ROB" -> {{nombrePropio, nivelPropio, clasePropia, vidaPropia + fuerza}, {nombreEnemigo, nivelEnemigo, claseEnemigo, vidaEnemigo - fuerza}}
        end  
    end

    def aplicarHechizos(jugador, [], enemigo)
    do
        {jugador, enemigo}
    end

    def aplicarHechizos(jugador, hechizos, enemigo)
        when is_list(hechizos)
    do
        {jugador, enemigo} = aplicarHechizos(jugador, tl(hechizos), enemigo);
        aplicarHechizo(jugador, hd(hechizos), enemigo)
    end

    def subirNivel({nombre, nivel, clase, vida})
    do
        {nombre, nivel + 1, clase, Clase.getVidaMax(clase, nivel + 1)}
    end
end