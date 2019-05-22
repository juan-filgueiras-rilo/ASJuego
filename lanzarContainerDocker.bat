if "%1"=="" goto noargs


:args
    docker run^
        -it^
        --rm^
        -v "%cd%":/practica^
        -v "%homedrive%%homepath%\.mix":/root/.mix^
        -w /practica elixir^
        iex -S mix %1
    goto :eof

:noargs
    docker run^
        -it^
        --rm^
        -v "%cd%":/practica^
        -v "%homedrive%%homepath%\.mix":/root/.mix^
        -w /practica elixir^
        iex -S mix