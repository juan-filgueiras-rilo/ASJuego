#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ "$#" -eq 0 ]; then
    docker run \
    -it \
    --rm \
    -v "${DIR}":/practica \
    -v "${HOME}/.mix":/root/.mix \
    -w /practica elixir \
    iex -S mix
fi
if [ "$#" -eq 1 ]; then
    docker run \
    -it \
    --rm \
    -v "${pwd}":/practica \
    -v "${HOME}/.mix":/root/.mix \
    -w /practica elixir \
    iex -S mix run $1
fi

    
