#!/bin/bash
if [ "$#" -eq 0 ]; then
    docker run \
    -it \
    --rm \
    -v "/home/marco/FIC/Practicas/Tercero/Segundo Cuatrimestre/AS/practica":/practica \
    -v "/home/marco/.mix":/root/.mix \
    -w /practica elixir \
    iex -S mix
fi
if [ "$#" -eq 1 ]; then
    docker run \
    -it \
    --rm \
    -v "/home/marco/FIC/Practicas/Tercero/Segundo Cuatrimestre/AS/practica":/practica \
    -v "/home/marco/.mix":/root/.mix \
    -w /practica elixir \
    iex -S mix run $1
fi

    
