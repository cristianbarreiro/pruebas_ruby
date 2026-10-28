# frozen_string_literal: true

# = Sintaxis, comentarios y convenciones
#
# Ejecución: ruby examples/01_fundamentos/01_sintaxis_y_convenciones.rb
#
# Ruby es un lenguaje interpretado, dinámico y orientado a objetos: todo valor
# es un objeto (incluidos los números, nil y true). La sintaxis busca leerse como
# texto y evita el ruido: los paréntesis son opcionales en muchas llamadas, no
# se usa punto y coma al final de línea y cada expresión devuelve un valor.
#
# Convenciones de nombres (las comprueba RuboCop):
#   snake_case       -> variables, métodos, archivos      (total_price, load_file)
#   CamelCase        -> clases y módulos                   (InvoiceParser)
#   SCREAMING_CASE   -> constantes                         (MAX_RETRIES)
#   metodo?          -> predicados que devuelven booleano  (empty?, valid?)
#   metodo!          -> versión "peligrosa" de otro método (sort!, strip!)
#
# La primera línea del archivo (frozen_string_literal) congela los literales de
# String: no se pueden modificar en sitio y Ruby puede reutilizarlos en memoria.

puts "== Todo es un objeto =="
puts 42.class            # => Integer
puts 3.14.class          # => Float
puts nil.class           # => NilClass
puts 5.respond_to?(:+)   # => true: el operador + es un método

puts "\n== Cada expresión devuelve un valor =="
# `if` es una expresión: su resultado se puede asignar.
temperature = 31
label = if temperature > 30 then "calor" else "templado" end # rubocop:disable Style/OneLineConditional
puts label

# El último valor evaluado es el valor de retorno del método (retorno implícito).
def greet(name)
  "Hola, #{name}"
end
puts greet("Ada")

puts "\n== Paréntesis opcionales =="
puts(greet("Matz")) # con paréntesis
puts greet "Matz"   # sin paréntesis: válido, pero úsalo solo en llamadas simples

puts "\n== Comentarios =="
# Comentario de una línea.
#
# Los comentarios multilínea con =begin/=end existen, pero la comunidad prefiere
# varias líneas con #. Documenta el *porqué* de una decisión, no el *qué* evidente.
puts "Los comentarios no generan salida"

puts "\n== Métodos con ? y ! =="
words = %w[pera manzana uva]
puts words.empty?          # predicado: devuelve true/false
sorted = words.sort        # devuelve un nuevo array
puts sorted.inspect
puts words.inspect         # el original no cambió
words.sort!                # versión con ! modifica el receptor
puts words.inspect

puts "\n== Error común: confundir = con == =="
# `if total = 0` asigna 0 (y siempre sería "verdadero" en Ruby, porque 0 no es
# falsy). Ruby emite un warning y RuboCop lo señala. Compara con ==:
total = 0
puts total.zero? ? "total es cero" : "total distinto de cero"
