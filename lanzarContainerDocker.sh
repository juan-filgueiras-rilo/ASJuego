#!/bin/bash
if [ "$#" -eq 0 ]; then
    sudo docker run \
    -it \
    --rm \
    -v "${pwd}":/practica \
    -v "${HOME}/.mix":/root/.mix \
    -w /practica elixir \
    iex -S mix
fi
if [ "$#" -eq 1 ]; then
    sudo docker run \
    -it \
    --rm \
    -v "${pwd}":/practica \
    -v "${HOME}/.mix":/root/.mix \
    -w /practica elixir \
    iex -S mix run $1
fi

    
