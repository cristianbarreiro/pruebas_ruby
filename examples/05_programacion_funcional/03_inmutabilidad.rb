# frozen_string_literal: true

# = Inmutabilidad y efectos secundarios
#
# Ejecución: ruby examples/05_programacion_funcional/03_inmutabilidad.rb
#
# Un efecto secundario es cualquier cambio observable fuera de la función:
# modificar un argumento, escribir en disco, imprimir, cambiar una global.
# Las funciones sin efectos secundarios ("puras") son más fáciles de probar y
# de razonar. Ruby no impone inmutabilidad, pero ofrece herramientas:
#
#   freeze          impide modificar el objeto (superficial: no congela lo que contiene)
#   dup / clone     copias superficiales (clone conserva el estado frozen)
#   Data.define     objetos de valor inmutables (Ruby 3.2+)
#   métodos sin !   devuelven un objeto nuevo en lugar de modificar el receptor

Point = Data.define(:x, :y) do
  # devuelve un Point nuevo
  def translate(delta_x, delta_y) = with(x: x + delta_x, y: y + delta_y)
end

# Impura: modifica el array que recibe.
def add_tax_in_place!(prices)
  prices.map! { |price| (price * 1.19).round }
end

# Pura: devuelve un array nuevo y deja intacta la entrada.
def with_tax(prices)
  prices.map { |price| (price * 1.19).round }
end

puts "== Pura frente a impura =="
original = [100, 200]
puts with_tax(original).inspect
puts "original tras with_tax: #{original.inspect}"
add_tax_in_place!(original)
puts "original tras add_tax_in_place!: #{original.inspect}"

puts "\n== freeze es superficial =="
config = { hosts: %w[a b] }.freeze
begin
  config[:port] = 80
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
config[:hosts] << "c" # el array interno NO está congelado
puts "hosts mutado igualmente: #{config[:hosts].inspect}"

deep = { hosts: %w[a b].freeze }.freeze
puts "Congelado en profundidad: #{deep[:hosts].frozen?}"

puts "\n== dup frente a clone =="
frozen_text = "texto"
puts frozen_text.dup.frozen?   # false: dup descongela
puts frozen_text.clone.frozen? # true: clone conserva el estado

puts "\n== Data: objetos de valor =="
origin = Point.new(x: 0, y: 0)
moved = origin.translate(3, 4)
puts origin.inspect, moved.inspect
puts origin == Point.new(x: 0, y: 0) # igualdad por valor
begin
  origin.instance_variable_set(:@x, 10)
rescue FrozenError => e
  puts "Data es inmutable: #{e.class}"
end

puts "\n== Error común: modificar un argumento sin avisar =="
def normalize(names)
  names.map(&:strip) # sin ! y sin map!: el llamador conserva sus datos
end
input = [" ana ", "luis "]
puts normalize(input).inspect
puts "input intacto: #{input.inspect}"
puts "Si un método modifica su argumento, indícalo con ! en el nombre y documéntalo."
