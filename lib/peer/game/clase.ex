defmodule Clase do
    use Guardable;

    def constructor(nombre, constVid, linVid, cuadVid, hechizos)
        when is_binary(nombre)
        and is_integer(constVid)
        and is_integer(linVid)
        and is_integer(cuadVid)
        and is_list(hechizos)
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

    def getHechizos({_, _, _, _, hechizos})
    do
        hechizos
    end

    def getNombre({nombre, _, _, _, _})
    do
        nombre
    end

    def getHechizosDisponibles({_, _, _, _, hechizos}, nivel)
    do
        Enum.filter(hechizos, fn x -> Hechizo.getNivelMin(x) >= nivel end)
    end


    def load(datos)
    do
        {
            datos["nombre"],
            datos["constVid"],
            datos["linVid"],
            datos["cuadVid"],
            Enum.map(datos["hechizos"], fn y -> Hechizo.load(y) end)
        }
    end



    def save({nombre, constVid, linVid, cuadVid, hechizos})
    do
        %{
            "nombre" => nombre,
            "constVid" => constVid,
            "linVid" => linVid,
            "cuadVid" => cuadVid,
            "hechizos" => Enum.map(hechizos, fn x -> Hechizo.save(x) end)
        }
    end

end