pidDebug = DebugGuay.debug();
{:ok, pidJuego} = GameFacade.iniciar(pidDebug, "./data/GameData.json");
GameFacade.cargar(pidJuego, "./data/PlayerData.json");
GameFacade.ackCombate()