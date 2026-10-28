# frozen_string_literal: true

# = Conjuntos (Set)
#
# Ejecución: ruby examples/02_estructuras_de_datos/03_sets.rb
#
# Set es una colección sin duplicados ni orden semántico. Comprobar pertenencia
# (include?) es O(1) en promedio, frente a O(n) en un Array.
# Desde Ruby 3.2 Set se carga automáticamente; en Ruby 4.0 forma parte del núcleo.

puts "== Creación =="
tags = Set.new(%w[ruby cli ruby testing])
puts tags.inspect                    # el duplicado desaparece
puts tags.size
tags << "ruby"                       # añadir un existente no cambia nada
puts tags.add?("ruby").inspect       # add? devuelve nil si ya existía
puts tags.include?("cli")

puts "\n== Operaciones de conjuntos =="
backend = Set[:ruby, :sql, :docker]
frontend = Set[:javascript, :css, :docker]
puts (backend | frontend).inspect    # unión
puts (backend & frontend).inspect    # intersección
puts (backend - frontend).inspect    # diferencia
puts (backend ^ frontend).inspect    # diferencia simétrica
puts Set[:ruby].subset?(backend)
puts backend.disjoint?(Set[:go])

puts "\n== Caso práctico: permisos =="
required = Set[:read, :write]
granted = Set[:read]
missing = required - granted
puts missing.empty? ? "Acceso concedido" : "Faltan permisos: #{missing.to_a.join(', ')}"

puts "\n== Error común: usar Array#include? en bucles grandes =="
blocked_ids = (1..10_000).to_a
blocked_set = blocked_ids.to_set
puts "Array#include? recorre hasta 10.000 elementos por consulta: #{blocked_ids.include?(9_999)}"
puts "Set#include? es O(1) promedio: #{blocked_set.include?(9_999)}"
puts "Convierte a Set una vez si vas a consultar muchas veces."
