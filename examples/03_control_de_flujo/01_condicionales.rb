# frozen_string_literal: true

# = Condicionales: if, unless, case y pattern matching
#
# Ejecución: ruby examples/03_control_de_flujo/01_condicionales.rb
#
# * if/elsif/else y unless son expresiones: devuelven un valor.
# * Los modificadores (`accion if condicion`) sirven para una sola línea simple.
# * case/when compara con ===, que cada clase define a su manera: Range
#   comprueba inclusión, Class comprueba tipo, Regexp comprueba coincidencia.
# * case/in (pattern matching, Ruby 3+) desestructura hashes y arrays.

def classify_temperature(celsius)
  if celsius < 0
    "helada"
  elsif celsius < 18
    "frío"
  elsif celsius < 28
    "templado"
  else
    "calor"
  end
end

def grade(score)
  case score
  when 90..100 then "A"
  when 75...90 then "B"
  when 60...75 then "C"
  when Integer then "Reprobado"
  else "Puntaje inválido"
  end
end

def describe(value)
  case value
  when nil then "nada"
  when String, Symbol then "texto: #{value}"
  when /\A\d+\z/ then "dígitos" # nunca se alcanza: String ya coincidió antes
  when Numeric then "número #{value}"
  when Array then "lista de #{value.size}"
  else "otro (#{value.class})"
  end
end

# Pattern matching: valida la forma del dato y extrae variables a la vez.
def handle(event)
  case event
  in { type: "payment", amount: Integer => amount } if amount.positive?
    "Pago recibido: #{amount}"
  in { type: "refund", amount: }
    "Reembolso de #{amount}"
  in { type: String => type }
    "Evento desconocido: #{type}"
  in [first, *]
    "Lote de eventos que empieza por #{first}"
  else
    "Formato inválido"
  end
end

puts "== if / elsif / else =="
[-3, 10, 22, 35].each { |temp| puts "#{temp}°C -> #{classify_temperature(temp)}" }

puts "\n== unless y modificadores =="
stock = 0
puts "Sin stock" unless stock.positive?
puts "Hay stock" if stock.positive?
puts stock.zero? ? "ternario: agotado" : "ternario: disponible"

puts "\n== case / when =="
[95, 80, 61, 10, 120].each { |score| puts "#{score} -> #{grade(score)}" }
[nil, "hola", 42, [1, 2], 3.5..4].each { |value| puts describe(value) }

puts "\n== case / in (pattern matching) =="
puts handle({ type: "payment", amount: 1500 })
puts handle({ type: "refund", amount: 300 })
puts handle({ type: "login" })
puts handle(%w[evento_a evento_b])
puts handle(42)

puts "\n== Error común: unless con else o condiciones negadas =="
# `unless !activo ... else ... end` obliga a una doble negación mental.
# Regla: usa unless solo con condiciones simples y sin else.
active = true
puts active ? "Activo" : "Inactivo"

puts "\n== Error común: el orden de los when importa =="
puts "describe('123') devuelve #{describe('123').inspect}: String coincide antes que la regex."
