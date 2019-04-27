'''
defmodule Interfaz do

  def inicio() do
	IO.puts ("Hola! Bienvenido a xxxxxxxxxxxx\n")
	mipid = self()
	pid = spawn(fn -> Interfaz.menu(mipid) end)
	IO.puts ("Introduzca 1 para buscar rival")
	IO.puts ("Introduzca 2 para mostrar estadisticas")
	IO.puts ("Introduzca 3 para finalizar el juego\n")
	recibir(pid)
  end
	
  def recibir(pid) do
	op = IO.gets("")
	IO.puts("")
	send pid, {:op, op}
	
	receive do
		:menu ->  	IO.puts ("Introduzca 1 para buscar rival")
					IO.puts ("Introduzca 2 para mostrar estadisticas")
					IO.puts ("Introduzca 3 para finalizar el juego\n")
					IO.puts ("((TEMPORAL DE PRUEBA)) 4. Iniciar juego \n")
					recibir(pid)
		:exit -> :ok
	end
  end
  
  def finalizar("3\n") do
	Process.exit(self(), :normal)
  end
  
  def finalizar(_) do
  end
  
  def menu(pid) do
	receive do
		{:op, op} -> operaciones(op, pid)
		{:start, pid} -> IO.puts ("Recibida conexion")
						 IO.puts ("Usted desea jugar? (S\N)")
						 juego(op)
						 menu(pid)
	end
  end
  
  def juego() do
    op = IO.gets("")
  end
  
  def op_juego(S) do
	IO.puts ("A jugar!")
  end
  
  def op_juego(N) do
	:ok
  end
  
  def op_juego(_) do
	IO.puts ("Opcion erronea")
	juego()
  end
  
  def operaciones("1\n", pid) do
	IO.puts ("Buscando rival...\n")
	send pid, :menu
	menu(pid)
  end
  
  def operaciones("2\n", pid) do
	IO.puts ("Mostrando estadisticas...\n")
	send pid, :menu
	menu(pid)
  end
  
  def operaciones("3\n", pid) do
	IO.puts ("Juego finalizado\n")
	send pid, :exit
  end
  
  def operaciones("4\n", pid) do
	IO.puts ("Juego finalizado\n")
	send pid, :exit
  end
  
  def operaciones(_, pid) do
	IO.puts ("Opcion erronea...\n")
	send pid, :menu
	menu(pid)
  end
  
end
'''