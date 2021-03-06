defmodule Hechizo do
  use Guardable

  def constructor(nombre, const, lineal, cuadr, nivelMin, tipo, duracion, descripcion, enfr) do
    {nombre, const, lineal, cuadr, nivelMin, tipo, duracion, descripcion, enfr}
  end

  def getNivelMin({_, _, _, _, nivelMin, _, _, _, _}) do
    nivelMin
  end

  def getNombre({nombre, _, _, _, _, _, _, _, _}) do
    nombre
  end

  def getFuerza({_, const, lineal, cuadr, _, _, _, _, _}, nivel) do
    const + lineal * nivel + cuadr * nivel * nivel
  end

  def getTipo({_, _, _, _, _, tipo, _, _, _}) do
    tipo
  end

  def getDuracion({_, _, _, _, _, _, duracion, _, _}) do
    duracion
  end

  def getEnfriamiento({_, _, _, _, _, _, _, _, enfr})
    do
        enfr
    end

  def save({nombre, const, lineal, cuadr, nivelMin, tipo, duracion, descripcion, enfr}) do
    %{
      "nombre" => nombre,
      "const" => const,
      "lineal" => lineal,
      "cuadr" => cuadr,
      "nivelMin" => nivelMin,
      "tipo" => tipo,
      "duracion" => duracion,
      "descripcion" => descripcion,
      "enfr" => enfr
    }
  end

  def load(datos) do
    {
      datos["nombre"],
      datos["const"],
      datos["lineal"],
      datos["cuadr"],
      datos["nivelMin"],
      datos["tipo"],
      datos["duracion"],
      datos["descripcion"],
      datos["enfr"]
    }
  end
end
