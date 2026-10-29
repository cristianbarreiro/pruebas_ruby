# frozen_string_literal: true

# = Bucles: while, until, for y métodos iteradores
#
# Ejecución: ruby examples/03_control_de_flujo/02_bucles_e_iteradores.rb
#
# Ruby tiene bucles clásicos (while, until, for), pero el estilo idiomático
# usa métodos iteradores (each, times, upto, step, loop) que reciben un bloque.
# Ventajas de los iteradores: no hay índice que gestionar a mano, las variables
# del bloque no "escapan" y se encadenan con map, select, etc.

puts "== while y until =="
countdown = 3
while countdown.positive?
  print countdown, " "
  countdown -= 1
end
puts "¡despegue!"

attempts = 0
attempts += 1 until attempts >= 3
puts "attempts = #{attempts}"

puts "\n== for (existe, pero se usa poco) =="
# rubocop:disable-next Style/For -- se muestra for para compararlo con each
for fruit in %w[pera uva]
  puts fruit
end
puts "La variable del for sigue existiendo fuera del bucle: fruit = #{fruit.inspect}"

puts "\n== Iteradores =="
3.times { |i| print i, " " }
puts
1.upto(4) { |i| print i, " " }
puts
10.step(0, -5) { |i| print i, " " }
puts
%w[a b c].each_with_index { |letter, index| print "#{index}:#{letter} " }
puts

puts "\n== loop, break y next =="
number = 0
loop do
  number += 1
  next if number.odd?   # salta a la siguiente iteración
  break if number > 6   # termina el bucle

  print number, " "
end
puts

# break puede devolver un valor:
first_big = [3, 8, 12, 20].each { |n| break n if n > 10 }
puts "Primer número > 10: #{first_big}"

puts "\n== Error común: bucles con índice manual =="
names = %w[Ana Luis Eva]
puts "Idiomático: #{names.map(&:upcase).join(", ")}"
puts "Si necesitas el índice, usa each_with_index o each.with_index(1):"
names.each.with_index(1) { |name, position| puts "#{position}. #{name}" }

puts "\n== Error común: bucle infinito por no actualizar la condición =="
puts "En while/until asegúrate de modificar la variable de control en cada vuelta;"
puts "con iteradores (times, each) ese error no puede ocurrir."
