# frozen_string_literal: true

# = Imperativo frente a idiomático: encadenamiento de métodos
#
# Ejecución: ruby examples/05_programacion_funcional/02_imperativo_vs_idiomatico.rb
#
# Problema: a partir de una lista de empleados, obtener los nombres en
# mayúsculas de quienes pertenecen a "ventas" y ganan más de 1.000, ordenados
# por salario descendente.
#
# Se comparan dos soluciones con el mismo resultado. La versión encadenada es
# más corta y expresa la intención en pasos con nombre; la imperativa hace una
# sola pasada y puede ser útil cuando hay que salir antes o el rendimiento es
# crítico. Criterio: empieza por la versión legible; optimiza si mides un problema.

Employee = Data.define(:name, :department, :salary)

EMPLOYEES = [
  Employee.new(name: "ana", department: "ventas", salary: 1500),
  Employee.new(name: "luis", department: "soporte", salary: 1200),
  Employee.new(name: "eva", department: "ventas", salary: 900),
  Employee.new(name: "leo", department: "ventas", salary: 2100)
].freeze

# rubocop:disable-next Style/MapIntoArray -- versión imperativa mostrada a propósito para comparar
def imperative(employees)
  selected = []
  employees.each do |employee|
    selected << employee if employee.department == "ventas" && employee.salary > 1000
  end
  sorted = selected.sort { |a, b| b.salary <=> a.salary }
  names = []
  sorted.each { |employee| names << employee.name.upcase }
  names
end

def idiomatic(employees)
  employees
    .select { |employee| employee.department == "ventas" && employee.salary > 1000 }
    .sort_by { |employee| -employee.salary }
    .map { |employee| employee.name.upcase }
end

puts "== Resultados =="
puts "Imperativo: #{imperative(EMPLOYEES).inspect}"
puts "Idiomático: #{idiomatic(EMPLOYEES).inspect}"
puts "Iguales? #{imperative(EMPLOYEES) == idiomatic(EMPLOYEES)}"

puts "\n== Más comparaciones breves =="
numbers = (1..10).to_a
# Contar pares
count = 0
numbers.each { |n| count += 1 if n.even? }
puts "imperativo: #{count} | idiomático: #{numbers.count(&:even?)}"
# ¿Existe alguno mayor que 8?
found = false
numbers.each do |n|
  if n > 8
    found = true
    break
  end
end
puts "imperativo: #{found} | idiomático: #{numbers.any? { |n| n > 8 }}"

puts "\n== Error común: cadenas larguísimas e ilegibles =="
puts "Si una cadena supera 4-5 pasos o necesita comentarios, extrae pasos a métodos con nombre:"

def sales_staff(employees) = employees.select { |employee| employee.department == "ventas" }
def well_paid(employees) = employees.select { |employee| employee.salary > 1000 }
puts well_paid(sales_staff(EMPLOYEES)).map(&:name).inspect
