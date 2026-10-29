# frozen_string_literal: true

# = Strings, interpolación, símbolos y rangos
#
# Ejecución: ruby examples/01_fundamentos/05_strings_simbolos_y_rangos.rb
#
# String es una secuencia mutable de caracteres con codificación (UTF-8 por
# defecto). Symbol es un identificador inmutable y único, ideal como clave de
# hash o nombre. Range representa un intervalo y es perezoso: 1..1_000_000 no
# crea un millón de elementos hasta que se recorre.

puts "== Strings e interpolación =="
name = "Grace"
puts "Hola, #{name}"          # comillas dobles: interpolan y aceptan \n, \t
puts 'Hola, #{name}'          # rubocop:disable Lint/InterpolationCheck -- comillas simples: texto literal
puts "Suma: #{2 + 3}"         # se interpola cualquier expresión

puts "\n== Métodos frecuentes =="
title = "  ruby práctico  "
puts title.strip.inspect
puts title.strip.capitalize
puts title.upcase
puts title.strip.length       # cuenta caracteres, no bytes
puts title.strip.bytesize     # la "á" ocupa 2 bytes en UTF-8
puts "a,b,,c".split(",").inspect
puts %w[uno dos tres].join(" | ")
puts "ruby".center(10, "*")
puts "Ruby" * 3
puts "hola mundo".include?("mundo")
puts "hola mundo".sub("mundo", "Ruby")
puts "archivo.rb".end_with?(".rb")

puts "\n== Heredoc para textos largos =="
report = <<~TEXT
  Informe de #{name}
    - La indentación común se elimina con <<~
    - La interpolación funciona igual que con comillas dobles
TEXT
puts report

puts "\n== Formato =="
puts "Café           2.50"

puts "\n== Símbolos =="
status = :active
puts status.inspect
puts status
puts %i[draft active archived].include?(status)

puts "\n== Rangos =="
puts (1..5).to_a.inspect      # inclusivo
puts (1...5).to_a.inspect     # excluye el final
puts ("a".."e").to_a.join
puts (1..10).step(3).to_a.inspect
puts (1..10).include?(7)
adults = (18..)               # rango sin fin
puts adults.include?(40)
puts "abcdef"[1..3]           # rangos como índices
puts "abcdef"[-2..]

puts "\n== Error común: mutar un literal congelado =="
greeting = "hola"
begin
  greeting << " mundo" # el literal está congelado por frozen_string_literal
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
mutable = +"hola"      # el + unario devuelve una copia descongelada
mutable << " mundo"
puts mutable
puts "Mejor aún: construye un String nuevo con interpolación en lugar de mutar."
