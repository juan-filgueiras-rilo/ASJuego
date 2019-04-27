defmodule Interfaz do

  def inicio() do
	IO.puts ("Hola! Bienvenido a xxxxxxxxxxxx\n")
	pid = spawn(fn -> Interfaz.menu() end)
	recibir(pid)
  end
	
  def recibir(pid) do
	IO.puts ("Introduzca 1 para buscar rival")
	IO.puts ("Introduzca 2 para mostrar estadisticas")
	IO.puts ("Introduzca 3 para finalizar el juego\n")
	op = IO.gets("")
	IO.puts ("\n")
	send pid, {:op, op}
	finalizar(op)
	:timer.sleep(1000);
	recibir(pid)
  end
  
  def finalizar("3\n") do
	Process.exit(self(), :normal)
  end
  
  def finalizar(_) do
  end
  
  def menu() do
	receive do
		{:op, op} -> operaciones(op)
					 menu()
	end
  end
  
  
  def operaciones("1\n") do
	IO.puts ("Buscando rival...\n")
  end
  
  def operaciones("2\n") do
	IO.puts ("Mostrando estadisticas...\n")
  end
  
  def operaciones("3\n") do
	IO.puts ("Finalizando juego...\n")
	Process.exit(self(), :normal)
  end
  
  def operaciones(_) do
	IO.puts ("Opcion erronea...\n")
  end
  
end