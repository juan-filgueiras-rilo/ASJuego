# Fachada de lógica de juego
Esta clase actúa como punto de entrada en el componente de lógica de juego, permitiendo ejecutar todas las operaciones necesarias para controlarlo y obtener información de él. 

### Ejemplo de uso:

Peer 1:

    # Se cargan los datos del juego
    {:ok, pid1} = GameFacade.iniciar("archivo", self())

    # Se cargan los datos del jugador
    GameFacade.cargar(pid1, "archivo2")

    # Se empieza a establecer un combate
    {pid1, jugador1} = GameFacade.synCombate(pid1)


Peer 2:

    # Se cargan los datos del juego
    {:ok, pid2} = GameFacade.iniciar("archivo", self())

    # Se cargan los datos del jugador
    GameFacade.cargar(pid2, "archivo2")

    # Se inicia el combate tomando los datos del peer1
    {pid2, jugador2} = GameFacade.ackCombate(pid2, pid1, jugador1)

Peer 1:
    
    # Se inicia el combate tomando los datos del peer2
    GameFacade.ackCombate(pid1, pid2, jugador2) # Aquí el combate comienza en ambos lados



## Inicialización
### iniciar(nombreArchivo, pidCallback)
* __Resumen:__ Arranca la lógica de juego, cargando la información de las clases y sus hechizos del fichero especificado. No se podrá empezar a jugar hasta que, o bien se carguen los datos del jugador con el método "cargar", o bien se cree uno nuevo con el método "crearJugador".
* __Argumentos:__
    * __nombreArchivo:__ El nombre del archivo que se usará para cargar la información de las clases.
    * __pidCallback:__ El pid de la interfaz que se usará para comunicar eventos (actualmente no implementado).
* __Valor de retorno:__
    * __{:ok, pid}__ El átomo ok, junto con el pid del proceso de control del estado del juego.
* __Errores:__
    * __:error__ Ocurrió un error durante la carga de los datos iniciales.
### CrearJugador
* __Resumen:__ Crea un nuevo jugador de nivel 1 para poder empezar a jugar.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __jugador:__ Los datos del jugador que deben haber sido creados llamando a la función Jugador.constructor/3
* __Valor de retorno:__
    * __:ok__ No hubo ningún error durante la creación.
* __Errores:__
    * __:estadoInvalido__ Los datos del jugador ya habían sido cargados.
## Entrada/Salida de archivos
### Guardar
* __Resumen:__ Guarda los datos del jugador en el archivo especificado.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __fileNamePlayer:__ El nombre del archivo donde se guardarán los datos del jugador.
* __Valor de retorno:__
    * __:ok__ No hubo ningún error durante el guardado.
* __Errores:__
    * __:estadoInvalido__ Todavía no se tienen los datos del jugador cargados.
    * __:error__ Hubo un error y el guardado no pudo llevarse a cabo.

### Cargar
* __Resumen:__ Carga los datos del jugador del archivo especificado.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __fileNamePlayer:__ El nombre del archivo de donde se cargarán los datos del jugador.
* __Valor de retorno:__
    * __:ok__ No hubo ningún error durante la carga.
* __Errores:__
    * __:estadoInvalido__ Los datos del jugador ya habían sido cargados.
    * __:error__ Hubo un error y la carga no se pudo llevar a cabo.
## Obtención de información
### ListarClases
* __Resumen:__ Devuelve una lista conteniendo todas las clases cargadas por el juego.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
* __Valor de retorno:__
    * __clases__ La lista de clases

### ObtenerClase
* __Resumen:__ Busca los datos de una clase concreta a partir de su nombre.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __clase:__ El nombre de la clase a buscar.
* __Valor de retorno:__
    * __clase__ Los datos de la clase.
* __Errores:__
    * __:notFound__ No se encontró ninguna clase con el nombre especificado.
### ObtenerJugador
* __Resumen:__ Obtiene los datos del jugador.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
* __Valor de retorno:__
    * __jugador__ Los datos del jugador.
* __Errores:__
    * __:estadoInvalido__ Los datos del jugador no se habían cargado todavía.
## Combate
### SynCombate
* __Resumen:__ Inicia el proceso de establecimiento de combate con otro jugador. Devuelve el pid y los datos del jugador, y prepara el estado interno para el combate. Para establecer un combate, es necesario llamar a este método en uno de los dos peers, pero no en los dos.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
* __Valor de retorno:__
    * __{pid, jugador}__ Par conteniendo el pid del proceso de control del estado del juego, y los datos del jugador.
* __Errores:__
    * __:estadoInvalido__ Ya estaba en combate, o bien los datos del jugador no fueron cargados todavía.
### AckCombate
* __Resumen:__ Continúa el proceso de establecimiento de combate con otro jugador. Recibe el pid del proceso de control del juego del otro jugador (o el de un módulo de red que actúe como repetidor), y los datos de su jugador. Devuelve el pid y los datos de este jugador, e inicia el combate en este peer. Para establecer un combate, es necesario llamar a este método en ambos peers, despues de haber ejecutado el proceso de syn en uno de ellos.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __pidRed:__ El pid del otro proceso de control del estado del juego, o de un componente que actúe como repetidor entre ambos. El control del estado enviará mensajes para mantener la sincronizacion a este pid (no implementado todavía).
    * __datosEnemigo:__ Los datos del jugador enemigo.
* __Valor de retorno:__
    * __{pid, jugador}__ Par conteniendo el pid del proceso de control del estado del juego, y los datos del jugador.
* __Errores:__
    * __:estadoInvalido__ Ya estaba en combate, o bien los datos del jugador no fueron cargados todavía.
### Retirarse
* __Resumen:__ Te retiras del combate, manteniendo la vida que tenías en ese momento para el próximo combate.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
* __Valor de retorno:__
    * __:ok__ Te retiraste del combate.
* __Errores:__
    * __:estadoInvalido__ No estabas en combate.
### UsarHechizoPropio
* __Resumen:__ Utilizas un hechizo con tu personaje durante el combate. Ejecutar el hechizo implica que se avance un turno tuyo en la simulación.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __hechizo:__ Los datos del hechizo a utilizar.
* __Valor de retorno:__
    * __:continuar__ El hechizo se pudo lanzar correctamente, y el combate sigue adelante.
    * __:victoria__ El hechizo se pudo lanzar correctamente, y se ganó el combate.
* __Errores:__
    * __:estadoInvalido__ No estabas en combate.
    * __:turnoInvalido__ No era tu turno.
### UsarHechizoRemoto
* __Resumen:__ El enemigo utiliza un hechizo con su personaje durante el combate. Ejecutar el hechizo implica que se avance un turno suyo en la simulación.
* __Argumentos:__
    * __pid:__ El pid del proceso de control del estado del juego.
    * __hechizo:__ Los datos del hechizo a utilizar.
* __Valor de retorno:__
    * __:continuar__ El hechizo se pudo lanzar correctamente, y el combate sigue adelante.
    * __:derrota__ El hechizo se pudo lanzar correctamente, y se perdió el combate.
* __Errores:__
    * __:estadoInvalido__ No estabas en combate.
    * __:turnoInvalido__ No era el turno del enemigo.