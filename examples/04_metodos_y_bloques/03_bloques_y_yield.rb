# frozen_string_literal: true

# = Bloques y yield
#
# Ejecución: ruby examples/04_metodos_y_bloques/03_bloques_y_yield.rb
#
# Un bloque es un fragmento de código que se pasa a un método. Hay dos sintaxis:
#   { |x| ... }       -> convención para una sola línea (devuelve un valor)
#   do |x| ... end    -> convención para varias líneas
# Dentro del método, `yield` ejecuta el bloque; `block_given?` indica si existe.

# Un método que "envuelve" código: patrón muy usado (File.open, Benchmark, transacciones).
def with_timing(label)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  result = yield
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  puts format("%<label>s tardó %<ms>.3f ms", label: label, ms: elapsed * 1000)
  result
end

# Iterador propio: cede cada elemento al bloque. Sin bloque devuelve un Enumerator,
# igual que los iteradores de la biblioteca estándar.
def each_business_day(days)
  return enum_for(:each_business_day, days) unless block_given?

  days.each { |day| yield day unless %w[sábado domingo].include?(day) }
end

# Capturar el bloque como objeto con &block para guardarlo o reenviarlo.
class Button
  def initialize(label, &on_click)
    @label = label
    @on_click = on_click
  end

  def click
    @on_click ? @on_click.call(@label) : "#{@label}: sin acción"
  end
end

puts "== yield =="
sum = with_timing("suma") { (1..100_000).sum }
puts "resultado: #{sum}"

puts "\n== Iterador propio =="
week = %w[lunes martes sábado domingo miércoles]
each_business_day(week) { |day| print day, " " }
puts
puts each_business_day(week).map(&:upcase).inspect # sin bloque -> Enumerator

puts "\n== &block =="
save = Button.new("Guardar") { |label| "#{label}: datos guardados" }
puts save.click
puts Button.new("Vacío").click

puts "\n== Bloques que reciben varios valores =="
{ ruby: 1995, elixir: 2011 }.each { |language, year| puts "#{language} (#{year})" }

puts "\n== Error común: precedencia de {} frente a do...end =="
# `puts [1, 2].map do |n| n * 2 end` pasa el bloque a `puts`, no a `map`,
# e imprime un Enumerator. Con llaves el bloque se asocia a `map`:
puts [1, 2].map { |n| n * 2 }.inspect
puts "Regla: llaves para bloques de una línea cuyo valor usas; do...end para varias líneas."

puts "\n== Error común: yield sin bloque =="
def needs_block
  yield
end
begin
  needs_block
rescue LocalJumpError => e
  puts "LocalJumpError: #{e.message}. Usa block_given? o enum_for."
end
