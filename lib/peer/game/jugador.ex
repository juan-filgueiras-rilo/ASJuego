defmodule Jugador do

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
end