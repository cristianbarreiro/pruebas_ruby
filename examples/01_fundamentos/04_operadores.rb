# frozen_string_literal: true

# = Operadores aritméticos, de comparación y lógicos
#
# Ejecución: ruby examples/01_fundamentos/04_operadores.rb
#
# En Ruby casi todos los operadores son métodos: `a + b` equivale a `a.+(b)`.
# Por eso una clase propia puede definir +, ==, <=> o [] (ver módulo 07).

puts "== Aritméticos =="
puts 17 + 5
puts 17 - 5
puts 17 * 5
puts 17 / 5          # => 3 (entera)
puts 17 % 5          # => 2 (resto)
puts 2**10           # potencia
puts 17.divmod(5).inspect # => [3, 2]
puts(-7 / 2)         # => -4: la división entera redondea hacia -infinito
puts(-7.fdiv(2))

puts "\n== Comparación =="
puts 3 < 5
puts 3 == 3.0        # => true: compara valor # rubocop:disable Lint/FloatComparison -- didáctico
puts 3.eql?(3.0)     # => false: compara valor y tipo (lo usa Hash) # rubocop:disable Lint/FloatComparison
puts "a".equal?("a") # identidad: ¿es el mismo objeto?
puts (1 <=> 2).inspect # "nave espacial": -1, 0, 1 o nil si no son comparables
puts 5.between?(1, 10)
puts 5.clamp(1, 3)

puts "\n== Lógicos =="
logged_in = true
admin = false
puts logged_in && admin
puts logged_in || admin
puts !admin
# && y || devuelven uno de sus operandos, no necesariamente true/false:
puts "valor por defecto".inspect
puts "perfil".inspect

puts "\n== Asignación abreviada =="
count = 10
count += 5
count *= 2
puts count
cache = nil
cache ||= "calculado una sola vez" # asigna solo si cache es nil o false
cache ||= "no se usa"
puts cache

puts "\n== Navegación segura (&.) =="
user = nil
puts user&.upcase.inspect # => nil, sin NoMethodError

puts "\n== Error común: precedencia de and/or =="
# `and`/`or` tienen menor precedencia que `=`. Esta línea asigna true y luego
# evalúa `and false`, de modo que result queda en true:
result = true and false
puts "result = #{result} (sorpresa: se esperaba false)"
result = false
puts "con && result = #{result}"
puts "Regla: usa && y || en expresiones; and/or solo para control de flujo, si acaso."
