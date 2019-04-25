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
        when is_binary(datos)
    do
        leido = elem(JSON.decode(datos),1);
        {
            leido["nombre"],
            leido["nivel"],
            leido["clase"],
            leido["vida"]
        }
    end

    def save({nombre, nivel ,clase, vida})
    do
        elem(JSON.encode(%{
            "nombre" => nombre,
            "nivel" => nivel,
            "clase" => clase,
            "vida" => vida
        }),1)
    end

    def getHechizosDisponibles({_, nivel, clase, _})
    do
        Clase.getHechizosDisponibles(clase, nivel)
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
end