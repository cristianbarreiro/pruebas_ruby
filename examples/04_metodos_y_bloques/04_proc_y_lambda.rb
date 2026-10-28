# frozen_string_literal: true

# = Proc y lambda
#
# Ejecución: ruby examples/04_metodos_y_bloques/04_proc_y_lambda.rb
#
# Proc y lambda son bloques convertidos en objetos: se guardan en variables,
# se pasan como argumentos y se llaman con .call, .() o [].
#
# Diferencias clave:
#                       lambda                    proc
#   Aridad              estricta (ArgumentError)   flexible (rellena con nil)
#   `return` dentro     sale de la lambda          sale del MÉTODO que lo contiene

puts "== Creación y llamada =="
square = ->(x) { x * x }
shout = proc { |text| "#{text.upcase}!" }
puts square.call(4)
puts square.(5) # rubocop:disable Style/LambdaCall -- se muestran las tres sintaxis de llamada
puts square[6]
puts shout.call("hola")
puts square.lambda?, shout.lambda?

puts "\n== Aridad =="
puts shout.call("uno", "dos")             # el argumento extra se ignora
begin
  square.call(1, 2)
rescue ArgumentError => e
  puts "lambda estricta: #{e.message}"
end

puts "\n== return =="
def run_lambda
  inner = -> { return :desde_lambda }
  inner.call
  :fin_del_metodo # se alcanza: return solo salió de la lambda
end

def run_proc
  inner = proc { return :desde_proc }
  inner.call
  :fin_del_metodo # NO se alcanza: return salió de run_proc
end
puts run_lambda.inspect
puts run_proc.inspect

puts "\n== Pasar lambdas como estrategia =="
formatters = {
  plain: ->(amount) { amount.to_s },
  money: ->(amount) { format("$%.2f", amount) },
  percent: ->(amount) { "#{(amount * 100).round}%" }
}
formatters.each { |name, formatter| puts "#{name}: #{formatter.call(0.256)}" }

puts "\n== Symbol#to_proc y Method#to_proc =="
puts %w[ana luis].map(&:capitalize).inspect     # &:capitalize -> { |s| s.capitalize }
puts [1, 4, 9].map(&Math.method(:sqrt)).inspect # convierte un método en bloque

puts "\n== Composición y currying =="
add_tax = ->(price) { price * 1.19 }
round_up = lambda(&:ceil)
final_price = add_tax >> round_up              # primero add_tax, luego round_up
puts final_price.call(1000)
multiply = ->(a, b) { a * b }
triple = multiply.curry[3]
puts triple.call(7)

puts "\n== Error común: usar proc cuando se espera validación de argumentos =="
puts "Prefiere lambda para funciones: su aridad estricta detecta llamadas incorrectas."
