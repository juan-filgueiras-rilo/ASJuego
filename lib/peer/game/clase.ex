defmodule Clase do
    use Guardable;

    def constructor(nombre, constVid, linVid, cuadVid, hechizos)
    do
        {nombre, constVid, linVid, cuadVid, hechizos}
    end

    def getVidaMax(clase, nivel)
        when is_integer(nivel)
        and is_tuple(clase)
    do
        case clase do
            {_, const, lin, cuad, _} -> const + (lin * nivel) + (cuad * nivel * nivel)
            _ -> :error
        end
    end

    def load(datos)
        when is_binary(datos)
    do
        leido = elem(JSON.decode(datos),1);
        {
            leido["nombre"],
            leido["constVid"],
            leido["linVid"],
            leido["cuadVid"],
            Enum.map(leido["hechizos"], fn x -> Hechizo.load(x) end)
        }
    end

    def save({nombre, constVid, linVid, cuadVid, hechizos})
    do
        elem(JSON.encode(%{
            "nombre" => nombre,
            "constVid" => constVid,
            "linVid" => linVid,
            "cuadVid" => cuadVid,
            "hechizos" => Enum.map(hechizos, fn x -> Hechizo.save(x) end)
        }),1)
    end

end