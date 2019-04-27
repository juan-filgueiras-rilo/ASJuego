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
	IO.puts ("\n")
	send pid, {:op, op}
	
	receive do
		:menu ->  	IO.puts ("Introduzca 1 para buscar rival")
					IO.puts ("Introduzca 2 para mostrar estadisticas")
					IO.puts ("Introduzca 3 para finalizar el juego\n")
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
	end
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
	IO.puts ("Finalizando juego...\n")
	send pid, :exit
  end
  
  def operaciones(_, pid) do
	IO.puts ("Opcion erronea...\n")
	send pid, :menu
	menu(pid)
  end
  
end