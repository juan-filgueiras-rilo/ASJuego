defmodule Hechizo do
    use Guardable
    
    def constructor(nombre, const, lineal, cuadr, nivelMin, tipo, duracion, descripcion, enfr)
    do
        {nombre, const, lineal, cuadr, nivelMin, tipo, duracion, descripcion, enfr}
    end

    def save({nombre, const, lineal, cuadr, nivelMin, tipo, duracion, descripcion, enfr})
    do
        elem(JSON.encode([
            nombre: nombre,
            const: const,
            linea: lineal,
            cuadr: cuadr,
            nivelMin: nivelMin,
            tipo: tipo,
            duracion: duracion,
            descripcion: descripcion,
            enfr: enfr
        ]),1)
    end

    def load(datos)
    do
        elem(JSON.decode(datos),1)
    end
end