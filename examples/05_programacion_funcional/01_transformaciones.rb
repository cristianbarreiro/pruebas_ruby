# frozen_string_literal: true

# = map, select, reject, filter_map, reduce y each_with_object
#
# Ejecución: ruby examples/05_programacion_funcional/01_transformaciones.rb
#
# Estos métodos de Enumerable expresan QUÉ se quiere obtener en lugar de CÓMO
# recorrer la colección. Ninguno modifica la colección original.
#
#   map               transforma cada elemento         (n -> n)
#   select / filter   conserva los que cumplen          (n -> <=n)
#   reject            descarta los que cumplen          (n -> <=n)
#   filter_map        filtra y transforma en una pasada (n -> <=n)
#   reduce / inject   combina todo en un único valor    (n -> 1)
#   each_with_object  construye un objeto acumulador    (n -> objeto)

Order = Data.define(:id, :customer, :total, :status)

ORDERS = [
  Order.new(id: 1, customer: "Ana", total: 120, status: :paid),
  Order.new(id: 2, customer: "Luis", total: 80, status: :pending),
  Order.new(id: 3, customer: "Ana", total: 45, status: :paid),
  Order.new(id: 4, customer: "Eva", total: 300, status: :cancelled),
  Order.new(id: 5, customer: "Luis", total: 60, status: :paid)
].freeze

puts "== map =="
puts ORDERS.map(&:total).inspect
puts ORDERS.map { |order| "##{order.id} #{order.customer}" }.inspect

puts "\n== select / reject =="
paid = ORDERS.select { |order| order.status == :paid }
puts paid.map(&:id).inspect
puts ORDERS.reject { |order| order.status == :cancelled }.map(&:id).inspect

puts "\n== filter_map: filtrar y transformar a la vez =="
big_paid_ids = ORDERS.filter_map { |order| order.id if order.status == :paid && order.total > 50 }
puts big_paid_ids.inspect

puts "\n== reduce =="
puts ORDERS.map(&:total).reduce(0) { |sum, total| sum + total }
puts ORDERS.sum(&:total) # forma idiomática para sumas
puts ORDERS.map(&:total).reduce(:*).inspect.length.to_s + " dígitos en el producto" # rubocop:disable Style/StringConcatenation
longest = ORDERS.map(&:customer).reduce { |a, b| a.length >= b.length ? a : b }
puts longest

puts "\n== each_with_object: construir un hash =="
totals_by_customer = ORDERS.each_with_object(Hash.new(0)) do |order, totals|
  totals[order.customer] += order.total
end
puts totals_by_customer.inspect

puts "\n== Otras transformaciones frecuentes =="
puts ORDERS.group_by(&:status).transform_values(&:size).inspect
puts ORDERS.partition { |order| order.total >= 100 }.map { |group| group.map(&:id) }.inspect
puts ORDERS.max_by(&:total).id
puts ORDERS.sum(&:total).fdiv(ORDERS.size).round(2)
puts ORDERS.map(&:status).tally.inspect
puts ORDERS.to_h { |order| [order.id, order.total] }.inspect

puts "\n== Error común: usar map para efectos secundarios =="
# map construye un array nuevo; si solo quieres imprimir o guardar, usa each.
ORDERS.first(2).each { |order| puts "Notificando a #{order.customer}" }

puts "\n== Error común: reduce sin valor inicial sobre una colección vacía =="
puts [].reduce(:+).inspect          # => nil, no 0
puts [].reduce(0, :+).inspect       # => 0
puts [].sum.inspect                 # => 0
