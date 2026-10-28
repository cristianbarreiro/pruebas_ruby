# frozen_string_literal: true

# = Arrays
#
# Ejecución: ruby examples/02_estructuras_de_datos/01_arrays.rb
#
# Array es una lista ordenada, indexada desde 0, dinámica y heterogénea.
# Acceso por índice: O(1). Búsqueda por valor (include?, index): O(n).

puts "== Creación =="
numbers = [5, 3, 8, 1]
words = %w[rojo verde azul]           # array de strings sin comillas ni comas
matrix = Array.new(2) { Array.new(3, 0) } # el bloque crea un array nuevo por fila
puts numbers.inspect, words.inspect, matrix.inspect

puts "\n== Acceso =="
puts numbers[0]
puts numbers[-1]                      # índices negativos cuentan desde el final
puts numbers[10].inspect              # fuera de rango -> nil, no error
puts numbers.fetch(1)
puts numbers.fetch(10, "sin valor")   # fetch permite un valor por defecto
puts numbers.first(2).inspect
puts numbers.dig(0).inspect

puts "\n== Agregar y quitar =="
stack = []
stack.push(1)
stack << 2                            # alias habitual de push
stack.unshift(0)                      # al inicio
puts stack.inspect
puts stack.pop                        # quita del final
puts stack.shift                      # quita del inicio
puts stack.inspect

puts "\n== Operaciones habituales =="
puts numbers.sort.inspect
puts numbers.reverse.inspect
puts numbers.sum
puts numbers.minmax.inspect
puts [1, 2, 2, 3, nil].compact.uniq.inspect
puts ([1, 2, 3] & [2, 3, 4]).inspect  # intersección
puts ([1, 2] | [2, 3]).inspect        # unión sin duplicados
puts ([1, 2, 3] - [2]).inspect        # diferencia
puts [[1, 2], [3, [4]]].flatten.inspect
puts numbers.each_slice(2).to_a.inspect
puts numbers.include?(8)

puts "\n== Desestructuración =="
first, *rest = numbers
puts "first=#{first} rest=#{rest.inspect}"
latitude, longitude = [-33.45, -70.66]
puts "lat=#{latitude} lon=#{longitude}"

puts "\n== Error común: Array.new(n, objeto) comparte el mismo objeto =="
shared = Array.new(3, []) # ¡las tres posiciones apuntan al MISMO array!
shared[0] << :x
puts "Array.new(3, []) tras modificar [0]: #{shared.inspect}"
independent = Array.new(3) { [] } # el bloque se evalúa una vez por posición
independent[0] << :x
puts "Array.new(3) { [] } tras modificar [0]: #{independent.inspect}"

puts "\n== Error común: modificar un array mientras se recorre =="
values = [1, 2, 3, 4]
puts "Usa reject/select en lugar de delete dentro de each: #{values.reject(&:even?).inspect}"
