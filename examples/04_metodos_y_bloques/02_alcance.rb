# frozen_string_literal: true

# = Alcance de variables
#
# Ejecución: ruby examples/04_metodos_y_bloques/02_alcance.rb
#
# Ruby tiene "puertas de ámbito" (scope gates): `def`, `class` y `module` abren un
# ámbito nuevo y NO ven las variables locales externas. Los bloques, en cambio,
# sí ven y pueden modificar las variables locales del ámbito donde se crean.

total = 0

puts "== Los bloques ven las variables externas =="
[10, 20, 30].each { |amount| total += amount }
puts "total tras el bloque: #{total}"

puts "\n== def no ve las variables externas =="
def try_to_read_total
  defined?(total).inspect
end
puts "defined?(total) dentro del método: #{try_to_read_total}"

puts "\n== Las variables creadas en un bloque no salen de él =="
[1].each { |_n| created_inside = :temporal; puts "dentro: #{created_inside}" } # rubocop:disable Style/Semicolon
puts "fuera: defined?(created_inside) = #{defined?(created_inside).inspect}"

puts "\n== Variables locales del bloque (;) para evitar modificar las externas =="
value = "externo"
[1, 2].each do |n; value| # `value` es local al bloque y no toca la externa
  value = n * 100
end
puts "value sigue siendo #{value.inspect}"

puts "\n== Pasar datos explícitamente (lo recomendable) =="
def apply_discount(price, rate)
  price - (price * rate)
end
puts apply_discount(1000, 0.1)

puts "\n== Error común: sombrear una variable externa sin querer =="
item = "lápiz"
%w[goma regla].each do |current_item| # nombre distinto evita confusión
  puts "procesando #{current_item}"
end
puts "item sigue siendo #{item}"
puts "Si el parámetro del bloque se llamara `item`, ocultaría la variable externa"
puts "(RuboCop lo detecta con Lint/ShadowingOuterLocalVariable)."
