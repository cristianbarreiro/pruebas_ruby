# frozen_string_literal: true

# = Entrada y salida por consola
#
# Ejecución interactiva:  ruby examples/01_fundamentos/07_entrada_y_salida.rb
# Ejecución con tubería:  echo "Ada" | ruby examples/01_fundamentos/07_entrada_y_salida.rb
#
# Salida:
#   puts  -> imprime y añade salto de línea (arrays: un elemento por línea)
#   print -> imprime sin salto de línea
#   p     -> imprime #inspect y devuelve su argumento (útil para depurar)
#   pp    -> como p, pero formatea estructuras grandes
#   warn  -> escribe en $stderr (errores y diagnósticos, no datos)
#
# Entrada:
#   $stdin.gets devuelve la línea INCLUYENDO "\n", o nil al llegar al final (EOF).
#
# Decisión: el método `ask` recibe los flujos como parámetros para poder probarlo
# con StringIO sin teclado real.

require "stringio"

def ask(question, input: $stdin, output: $stdout)
  output.print "#{question} "
  answer = input.gets
  return nil if answer.nil? # EOF: el usuario pulsó Ctrl+D/Ctrl+Z o no hay tubería

  answer.chomp.strip
end

puts "== Salida =="
puts "puts con array:", %w[a b]
print "print sin salto", "\n"
p({ id: 1, tags: %w[ruby cli] })
pp({ nested: { deep: { value: [1, 2, 3] } } })
warn "(esto va a $stderr)"

puts "\n== Entrada real (vacía si no hay tubería) =="
name = ask("¿Cómo te llamas?")
puts
if name.nil? || name.empty?
  puts "No se recibió nombre; se usa 'invitado'."
  name = "invitado"
end
puts "Hola, #{name}!"

puts "\n== Entrada simulada con StringIO (como en las pruebas) =="
fake_input = StringIO.new("42\n")
fake_output = StringIO.new
age = ask("¿Edad?", input: fake_input, output: fake_output)
puts "Pregunta mostrada: #{fake_output.string.inspect}"
puts "Respuesta leída: #{age.inspect}"

puts "\n== Error común: olvidar chomp =="
raw = StringIO.new("sí\n").gets
puts "Sin chomp: #{raw.inspect} == 'sí' -> #{raw == "sí"}"
puts "Con chomp: #{raw.chomp.inspect} == 'sí' -> #{raw.chomp == "sí"}"
puts "Y comprueba nil: en EOF `gets.chomp` lanza NoMethodError."
