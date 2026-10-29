# frozen_string_literal: true

# = Definición de métodos, parámetros y valores de retorno
#
# Ejecución: ruby examples/04_metodos_y_bloques/01_definicion_y_parametros.rb
#
# Tipos de parámetros, en el orden en que deben declararse:
#   requeridos, opcionales (= valor), *splat, nombrados (clave:), **opciones, &bloque
#
# Los parámetros nombrados (keyword arguments) hacen explícito el significado de
# cada argumento en la llamada y permiten cambiar su orden sin romper nada.

# Parámetro posicional requerido y retorno implícito.
def square(number)
  number * number
end

# Parámetro opcional con valor por defecto.
def greet(name, greeting = "Hola")
  "#{greeting}, #{name}"
end

# Splat: recoge cualquier cantidad de argumentos en un array.
def average(*values)
  return 0.0 if values.empty? # retorno anticipado (guard clause)

  values.sum.fdiv(values.size)
end

# Parámetros nombrados: requeridos (sin valor) y opcionales (con valor).
def create_user(name:, email:, role: :reader, active: true)
  { name:, email:, role:, active: } # sintaxis abreviada de hash (Ruby 3.1+)
end

# **options recoge nombrados no declarados (úsalo con moderación).
def log_event(message, **metadata)
  details = metadata.map { |key, value| "#{key}=#{value}" }.join(" ")
  "[evento] #{message} #{details}".strip
end

# Devolver varios valores: en realidad se devuelve un Array que se desestructura.
def min_and_max(values)
  values.minmax
end

# Método de una sola expresión ("endless method", Ruby 3.0+).
def double(number) = number * 2

puts "== Posicionales y opcionales =="
puts square(7)
puts greet("Ana")
puts greet("Ana", "Buenos días")

puts "\n== Splat =="
puts average(4, 8, 9)
puts average
puts average(1, 2, 3) # el * en la llamada expande un array en argumentos

puts "\n== Nombrados =="
puts create_user(name: "Eva", email: "eva@example.com").inspect
puts create_user(email: "leo@example.com", name: "Leo", role: :admin).inspect
begin
  create_user(name: "Sin email")
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end

puts "\n== **options y retorno múltiple =="
puts log_event("login", user_id: 7, ip: "10.0.0.1")
low, high = min_and_max([4, 9, 1])
puts "low=#{low} high=#{high}"
puts double(21)

puts "\n== Error común: booleanos posicionales =="
# `export(data, true, false)` no dice nada al lector. Compáralo con:
def export(data, compress: false, include_headers: true)
  "export(#{data.size} filas, compress=#{compress}, headers=#{include_headers})"
end
puts export([1, 2, 3], compress: true)

puts "\n== Error común: valor por defecto mutable evaluado en cada llamada =="
# A diferencia de Python, Ruby evalúa el valor por defecto EN CADA llamada,
# así que `items = []` no se comparte entre llamadas:
def add_item(item, items = [])
  items << item
end
puts add_item(:a).inspect
puts add_item(:b).inspect # => [:b], no [:a, :b]
