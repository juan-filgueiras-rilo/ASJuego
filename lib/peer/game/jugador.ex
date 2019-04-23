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
end