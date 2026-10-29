# frozen_string_literal: true

# = Enumerators y evaluación diferida (lazy)
#
# Ejecución: ruby examples/05_programacion_funcional/04_evaluacion_diferida.rb
#
# Por defecto los métodos de Enumerable son "ansiosos": cada paso crea un array
# intermedio completo. Con .lazy, los pasos se aplican elemento a elemento y
# solo hasta obtener lo que se pide. Es útil con:
#   * secuencias infinitas o muy largas,
#   * fuentes costosas (líneas de un archivo grande, llamadas de red),
#   * cuando solo necesitas los primeros N resultados.
# Para colecciones pequeñas, lazy suele ser MÁS lento por su sobrecoste.

puts "== Secuencia infinita con lazy =="
primes = (2..).lazy.select { |n| (2..Integer.sqrt(n)).none? { |d| (n % d).zero? } }
puts primes.first(10).inspect

puts "\n== Cuántos elementos se procesan realmente =="
processed = 0
result = (1..1_000_000).lazy
                       .map { |n| processed += 1; n * 2 } # rubocop:disable Style/Semicolon
                       .select { |n| (n % 3).zero? }
                       .first(3)
puts "resultado: #{result.inspect}, elementos procesados: #{processed}"

puts "\n== Enumerator propio (generador) =="
fibonacci = Enumerator.new do |yielder|
  a = 0
  b = 1
  loop do
    yielder << a
    a, b = b, a + b
  end
end
puts fibonacci.take(12).inspect
puts fibonacci.lazy.select(&:even?).first(5).inspect

puts "\n== Enumerator.produce (Ruby 2.7+) =="
powers_of_two = Enumerator.produce(1) { |n| n * 2 }
puts powers_of_two.take(8).inspect

puts "\n== lazy sobre líneas (simulando un archivo grande) =="
lines = Enumerator.new { |y| 10_000.times { |i| y << "linea #{i} #{(i % 500).zero? ? "ERROR" : "ok"}" } }
first_errors = lines.lazy.grep(/ERROR/).first(2)
puts first_errors.inspect

puts "\n== Error común: olvidar forzar la evaluación =="
pending = (1..3).lazy.map { |n| n * 10 }
puts "Sin forzar: #{pending.class}"
puts "Forzado con to_a/first/force: #{pending.to_a.inspect}"

puts "\n== Error común: lazy en colecciones pequeñas =="
puts "Para 10 elementos usa map/select normales: más simples y más rápidos."
