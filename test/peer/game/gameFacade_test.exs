defmodule GameFacadeTest do
  use ExUnit.Case
  doctest GameFacade

  test "CreatePlayer" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    assert jugador == GameFacade.obtenerJugador(pid)
  end

  test "MultipleLoadsError" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    assert GameFacade.crearJugador(pid, jugador) == :estadoInvalido
  end

  test "ListSpellsOutOfCombatError" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    assert GameFacade.getHechizosDisponibles(pid) == :estadoInvalido
  end

  test "UseSpellTwotimesError" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    GameFacade.ackCombate(pid, self(), jugador)
    hechizos = GameFacade.getHechizosDisponibles(pid)
    GameFacade.usarHechizoPropio(pid, hd(hechizos))
    assert GameFacade.usarHechizoPropio(pid, hd(tl(hechizos))) == :turnoInvalido
  end

  test "UseSpellOutOfCombatError" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    assert GameFacade.usarHechizoPropio(pid, {:ok}) == :estadoInvalido
  end

  test "UseLocalSpell" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    GameFacade.ackCombate(pid, self(), jugador)
    hechizos = GameFacade.getHechizosDisponibles(pid)
    ori = GameFacade.obtenerEnemigo(pid)
    GameFacade.usarHechizoPropio(pid, hd(hechizos))
    result = GameFacade.obtenerEnemigo(pid)

    assert Jugador.getVida(ori) > Jugador.getVida(result)
  end

  test "UseRemoteSpell" do
    {:ok, pid} = GameFacade.iniciar("./data/GameData.json", self())
    clases = GameFacade.listarClases(pid)
    jugador = Jugador.constructor("prueba", 1, hd(clases))
    GameFacade.crearJugador(pid, jugador)
    GameFacade.ackCombate(pid, self(), jugador)
    hechizos = GameFacade.getHechizosDisponibles(pid)

    ori = GameFacade.obtenerJugador(pid)
    GameFacade.usarHechizoPropio(pid, hd(hechizos))
    GameFacade.usarHechizoRemoto(pid, hd(hechizos))
    result = GameFacade.obtenerJugador(pid)

    assert Jugador.getVida(ori) > Jugador.getVida(result)
  end
end
