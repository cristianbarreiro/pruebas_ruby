# frozen_string_literal: true

# = Tipos básicos y conversión de tipos
#
# Ejecución: ruby examples/01_fundamentos/03_tipos_y_conversiones.rb
#
# Tipos básicos: Integer (precisión arbitraria), Float (IEEE 754, aproximado),
# Rational (fracciones exactas), String, Symbol, true/false y nil.
#
# Ruby tiene dos familias de conversión:
#   to_i, to_f, to_s, to_a, to_sym -> permisivas: nunca fallan, "adivinan"
#   Integer(), Float(), String()    -> estrictas: lanzan error si la entrada no es válida

puts "== Tipos numéricos =="
puts 2**100                       # Integer sin desbordamiento
puts 7 / 2                        # => 3   (división entera)
puts 7 / 2.0                      # => 3.5 (si un operando es Float, el resultado también)
puts 7.fdiv(2)                    # => 3.5 de forma explícita
puts Rational(1, 3) + Rational(1, 6) # => 1/2, exacto

puts "\n== Float es aproximado =="
puts 0.1 + 0.2                    # => 0.30000000000000004
puts (0.1 + 0.2).round(2)
puts "Para dinero usa Integer (centavos) o BigDecimal, no Float."

puts "\n== Conversiones permisivas (to_*) =="
puts "42abc".to_i.inspect         # => 42 (ignora el resto)
puts "abc".to_i.inspect           # => 0  (¡silencioso!)
puts "3.7".to_f.inspect
puts 3.99.to_i.inspect            # => 3 (trunca, no redondea)
puts nil.to_a.inspect             # => []
puts :ok.to_s.inspect

puts "\n== Conversiones estrictas (Kernel#Integer, Float) =="
puts Integer("42").inspect
puts Integer("1A", 16).inspect # => 26, con base explícita
puts Integer("0b101").inspect # => 5, reconoce prefijos 0b, 0o, 0x
puts Integer("abc", exception: false).inspect # => nil en lugar de excepción
begin
  Integer("42abc")
rescue ArgumentError => e
  puts "Integer('42abc') falla: #{e.message}"
end

puts "\n== Símbolos frente a strings =="
puts :status.equal?(:status) # => true: un símbolo es único en memoria
puts :status.inspect
puts %w[a b].map(&:upcase).inspect # &:upcase convierte el símbolo en un bloque

puts "\n== Comprobar tipos =="
value = 10
puts value.is_a?(Integer)         # considera la herencia
puts value.is_a?(Numeric)         # Integer < Numeric
puts value.instance_of?(Numeric)  # false: solo la clase exacta

puts "\n== Error común: usar to_i para validar entradas =="
input = "doce"
puts "input.to_i devuelve #{input.to_i}: el error pasa desapercibido."
parsed = Integer(input, exception: false)
puts parsed.nil? ? "Integer() detecta que #{input.inspect} no es un número" : parsed
