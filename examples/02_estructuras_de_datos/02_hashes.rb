# frozen_string_literal: true

# = Hashes
#
# Ejecución: ruby examples/02_estructuras_de_datos/02_hashes.rb
#
# Hash es una colección de pares clave-valor que conserva el orden de inserción.
# Búsqueda, inserción y borrado por clave: O(1) en promedio. Las claves se
# comparan con #eql? y #hash, por eso 1 y 1.0 son claves distintas.

puts "== Creación y acceso =="
product = { name: "Teclado", price: 45_000, tags: %w[usb mecánico] }
puts product[:name]
puts product[:color].inspect                 # clave ausente -> nil
puts product.fetch(:price)
puts product.fetch(:color, "sin color")
puts product.dig(:tags, 0)                   # acceso anidado seguro
puts product.key?(:price)

puts "\n== Claves símbolo frente a string =="
from_json = { "name" => "Mouse" }            # JSON.parse genera claves string
puts from_json[:name].inspect                # nil: :name != "name"
puts from_json["name"]
puts from_json.transform_keys(&:to_sym).inspect

puts "\n== Modificar =="
product[:stock] = 12
product.delete(:tags)
puts product.inspect
updated = product.merge(price: 39_990)       # devuelve un hash nuevo
puts updated[:price], product[:price]

puts "\n== Recorrer y transformar =="
prices = { cafe: 2500, te: 1800, jugo: 3200 }
prices.each { |item, price| puts "#{item}: $#{price}" }
puts prices.select { |_item, price| price > 2000 }.inspect
puts prices.transform_values { |price| price * 2 }.inspect
puts prices.min_by { |_item, price| price }.inspect
puts prices.sum { |_item, price| price }
puts prices.sort_by { |_item, price| -price }.to_h.inspect
puts prices.to_a.inspect

puts "\n== Valores por defecto =="
counts = Hash.new(0)                         # valor por defecto inmutable: seguro
%w[a b a c a].each { |letter| counts[letter] += 1 }
puts counts.inspect
puts %w[a b a c a].tally.inspect             # equivalente idiomático

groups = Hash.new { |hash, key| hash[key] = [] } # el bloque crea un array por clave
groups[:pares] << 2
groups[:impares] << 1
puts groups.inspect

puts "\n== Error común: Hash.new([]) comparte el mismo array =="
broken = Hash.new([])
broken[:a] << 1                              # modifica el valor por defecto, no crea la clave
puts "broken = #{broken.inspect}, broken[:z] = #{broken[:z].inspect}"
puts "Usa Hash.new { |h, k| h[k] = [] } o group_by."
