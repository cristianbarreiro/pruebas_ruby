# frozen_string_literal: true

# = Closures y captura de variables
#
# Ejecución: ruby examples/04_metodos_y_bloques/05_closures.rb
#
# Un closure es una función que "recuerda" el entorno donde se creó. En Ruby,
# bloques, procs y lambdas capturan las variables locales POR REFERENCIA: ven
# su valor actual, no una copia del momento en que se crearon.

# Fábrica de contadores: cada lambda conserva su propia variable `count`.
def make_counter(start: 0)
  count = start
  increment = -> { count += 1 }
  current = -> { count }
  [increment, current]
end

# Configurar comportamiento con closures (sin crear una clase completa).
def make_validator(min:, max:)
  ->(value) { value.between?(min, max) }
end

puts "== Contadores independientes =="
increment_a, current_a = make_counter
increment_b, current_b = make_counter(start: 100)
3.times { increment_a.call }
increment_b.call
puts "A = #{current_a.call}, B = #{current_b.call}"

puts "\n== Validadores configurados =="
valid_age = make_validator(min: 18, max: 120)
valid_percent = make_validator(min: 0, max: 100)
puts valid_age.call(17), valid_percent.call(55)

puts "\n== Captura por referencia =="
discount = 0.1
apply = ->(price) { price * (1 - discount) }
puts apply.call(100)
discount = 0.5 # la lambda ve el nuevo valor
puts apply.call(100)

puts "\n== Error común: esperar que el closure copie el valor =="
callbacks = []
message = "primero"
callbacks << -> { message }
message = "modificado después"
puts "El callback devuelve #{callbacks.first.call.inspect}, no \"primero\"."
puts "Si necesitas fijar el valor, pásalo como argumento o captura una variable nueva:"

frozen_callbacks = %w[uno dos tres].map { |word| -> { word } } # cada iteración tiene su `word`
puts frozen_callbacks.map(&:call).inspect

puts "\n== Error común: closures que retienen objetos grandes =="
puts "Un closure mantiene vivas las variables que captura; evita capturar"
puts "colecciones enormes en callbacks de larga duración (impide liberar memoria)."
