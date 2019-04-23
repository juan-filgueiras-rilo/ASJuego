defmodule GameFacade do

#------------------------------------
# ESTA ZONA CONTIENE METODOS LOCALES
#------------------------------------

    defp generarMundo(fileName)
    do
        # Llamada por load cuando no hay disponible información del mundo.
        # Guarda automaticamente el mundo para posteriores usos.
        :todo
    end

    def constructor(fileName)
        when is_binary(fileName)
    do
        # Cargamos la información del jugador, de las clases y sus hechizos y
        # del mundo (si esta disponible). En caso de que el mundo no lo este,
        # usariamos el metodo generarMundo.
        :todo
    end

    def guardar(fileName, jugador)
    do
        # Guardamos la partida. Debemos recibir el jugador, ya que puede ser que
        # no lo tengamos en este mundo.
    end


    #
    # Esta zona se refiere al proceso de linkado de mundos. Es el que sigue:
    # 
    # 1) Se inicia el linkado llamando al metodo "startLinkWorld" en uno de los peers.
    #    Esta funcion nos devuelve una propuesta de sectores para ser enlazados, y un
    #    nombre que se le mostrará al otro peer para referirse a este mundo.
    #
    # 2) Se finaliza el proceso de linkado llamando al metodo "linkWorld" en el otro peer.
    #    Esta función recibe la información generada por el otro peer junto con el atomo
    #    :generate , y enlaza los sectores localmente  devolviendo los datos de los
    #    enlaces establecidos entre los mundos.
    #
    # 3) En el peer inicial se llama al metodo "linkWorld" con el atomo :link.
    #    Este metodo ya recibe los enlaces establecidos por el peer entre los sectores
    #    de ambos peers, y los establece localmente.
    #
    # 4) Si un peer quisiera desconectar un mundo, debería llamar a "unlinkWorld"
    #    pasando el nombre del enlace. Este metodo solo desconecta los enlaces de un
    #    lado del peer. Es responsabilidad del componente correspondiente (red o IU)
    #    desconectar el otro lado (si es que sigue vivo).
    #

    def startLinkWorld(gameState)
    do
        # Comienza el proceso de conexión de nuestro mundo. Aquí devolvemos el nombre
        # y sectores que proponemos para el enlace.
    end

    def linkWorld(gameState, {:generate, nombre, sectores})
    do
        # Enlaza nuestro mundo. Aquí nos están proponiendo
        # ya unos sectores, así que devolvemos los enlaces establecidos entre sus sectores
        # y los nuestros.
        :todo
    end

    def linkWorld(gameState, {:link, enlaces})
    do
        :todo
    end

    def unlinkWorld(gameState, nombre)
    do
        :todo
        # Desenlaza el mundo representado por nombre de nuestro mundo
    end


#--------------------------------------------------------
# ESTA ZONA PUEDE USARSE POR OTROS PEERS EN NUESTRO MUNDO
#--------------------------------------------------------


    def getJugador(gameState, id)
    do
        #Devolvemos una referencia al jugador, aunque es de solo lectura
        case gameState do
            {jugadores, mundo, clases, combates} -> Enum.find(jugadores, fn {idPriv, idPub, estado, jugador} -> idPub = id end)
            _ -> :error
        end
    end

    def login(gameState, player, sector, pidCallback)
    do
        # DEVOLVER (ID_PUB, ID_PRIV) DEL JUGADOR GENERADO AL CONECTARSE. En el sector
        # se almacena el id_pub del jugador
        
        # Ademas, el pidCallback es a donde se enviaran las respuestas a eventos
        # (como combates que se inician, resultados del combate, o enlaces establecidos).
        :todo
    end

    def logout(gameState, idPriv)
    do
        # Desconecta un jugador del mundo.
        :todo
    end

    def moverse(gameState, idPriv, sector)
    do
        # Te mueve a otro sector (dentro de los gestionados por este peer, si no 
        # habria que desloguearse aquí, y loguearse allí).
        :todo
    end

    def atacar(gameState, idPriv, idPub)
    do
        # Ataca (si es posible) al jugador identificado por idPub.
        :todo
    end

    def retirarse(gameState, idPriv)
    do
        # Te retiras del combate
        :todo
    end

    def usarHechizo(gameState, idPriv, hechizo)
    do
        # Usas un hechizo (solo funcionara si es tu turno, estas en combate y el idPriv es valido)
        
        :todo
    end

end