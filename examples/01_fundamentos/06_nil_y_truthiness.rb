# frozen_string_literal: true

# = nil, truthiness y valores falsy
#
# Ejecución: ruby examples/01_fundamentos/06_nil_y_truthiness.rb
#
# En Ruby solo hay DOS valores falsy: false y nil. Todo lo demás es truthy,
# incluidos 0, "" (string vacío), [] y {}. Esto difiere de JavaScript, Python
# o PHP, y es una fuente habitual de errores al llegar desde esos lenguajes.

def truthy?(value)
  value ? true : false
end

puts "== ¿Qué es truthy? =="
[false, nil, 0, "", [], {}, "false", 0.0].each do |value|
  puts format("%<value>-10s -> %<result>s", value: value.inspect, result: truthy?(value))
end

puts "\n== nil es un objeto =="
puts nil.class
puts nil.to_s.inspect
puts nil.to_a.inspect
puts nil.nil?

puts "\n== Cómo comprobar vacío =="
puts "".empty?
puts [].empty?
puts({}.empty?)
puts 0.zero?

puts "\n== Valores por defecto con || y fetch =="
config = { timeout: nil, retries: 0 }
puts (config[:timeout] || 30).inspect          # nil -> usa 30
puts (config[:retries] || 3).inspect           # 0 es truthy -> se conserva 0
puts config.fetch(:host, "localhost")          # clave ausente -> valor por defecto

puts "\n== Error común: || con false como valor válido =="
settings = { verbose: false }
verbose = settings[:verbose] || true # ¡false se convierte en true!
puts "Con ||: verbose = #{verbose}"
verbose = settings.fetch(:verbose, true)
puts "Con fetch: verbose = #{verbose}"

puts "\n== Error común: suponer que 0 o \"\" son falsy =="
items_count = 0
puts "Este mensaje se imprime aunque items_count sea 0" if items_count
puts "Usa .zero?, .empty? o .positive? para expresar la intención" if items_count.zero?
