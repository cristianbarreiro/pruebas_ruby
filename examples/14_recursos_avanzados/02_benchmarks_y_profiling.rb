# frozen_string_literal: true

# = Benchmarks y Profiling
#
# Medir el rendimiento es esencial para tomar decisiones informadas sobre
# optimización. Ruby incluye la librería estándar "benchmark" y ObjectSpace
# para medir tiempo y uso de memoria respectivamente.
#
# Regla de oro: "No optimices prematuramente. Mide primero, optimiza después."

require "benchmark"
require "set"

puts "=" * 70
puts " BENCHMARKS Y PROFILING EN RUBY"
puts "=" * 70

# ──────────────────────────────────────────────────────────────────────────────
# 1. Benchmark.measure - Medición simple
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 1. Benchmark.measure ──"

# measure retorna un objeto Benchmark::Tms con tiempos detallados
resultado = Benchmark.measure do
  suma = 0
  1_000_000.times { |idx| suma += idx }
end

puts "  Tiempos para sumar 1 millón de números:"
puts "    User CPU:   #{resultado.utime.round(4)}s"
puts "    System CPU: #{resultado.stime.round(4)}s"
puts "    Total CPU:  #{resultado.total.round(4)}s"
puts "    Real (wall):#{resultado.real.round(4)}s"
puts ""
puts "  Formato completo: #{resultado}"

# ──────────────────────────────────────────────────────────────────────────────
# 2. Benchmark.bm - Comparar múltiples implementaciones
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 2. Benchmark.bm ──"

iteraciones = 500_000

puts "  Comparando formas de construir un array de cuadrados (#{iteraciones} elementos):"
puts ""

Benchmark.bm(18) do |bench|
  bench.report("times + push:") do
    arr = []
    iteraciones.times { |idx| arr.push(idx * idx) }
  end

  bench.report("times + <<:") do
    arr = []
    iteraciones.times { |idx| arr << (idx * idx) }
  end

  bench.report("Array.new(block):") do
    Array.new(iteraciones) { |idx| idx * idx }
  end

  bench.report("map con Range:") do
    (0...iteraciones).map { |idx| idx * idx }
  end
end

# ──────────────────────────────────────────────────────────────────────────────
# 3. Benchmark.bmbm - Con ensayo previo (warm-up)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 3. Benchmark.bmbm (con warm-up) ──"

# bmbm ejecuta primero un "ensayo" para estabilizar el GC y la caché,
# luego ejecuta la medición real. Más preciso para mediciones cortas.

puts "  Comparando búsqueda: Array vs Set vs Hash"
puts ""

datos_array = (1..10_000).to_a
datos_set = datos_array.to_set
datos_hash = datos_array.each_with_object({}) { |val, hsh| hsh[val] = true }
buscar = [1, 5_000, 10_000, 99_999] # Incluye un elemento que no existe

Benchmark.bmbm(14) do |bench|
  bench.report("Array#include?") do
    50_000.times { buscar.each { |val| datos_array.include?(val) } }
  end

  bench.report("Set#include?") do
    50_000.times { buscar.each { |val| datos_set.include?(val) } }
  end

  bench.report("Hash#key?") do
    50_000.times { buscar.each { |val| datos_hash.key?(val) } }
  end
end

puts ""
puts "  💡 Array#include? es O(n), Set/Hash es O(1). Para búsquedas"
puts "     frecuentes, siempre preferir Set o Hash."

# ──────────────────────────────────────────────────────────────────────────────
# 4. Medición manual con Process.clock_gettime
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 4. Medición manual de alta resolución ──"

# Process.clock_gettime es más preciso que Time.now para benchmarks
def medir_tiempo_ns
  inicio = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
  yield
  fin = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
  fin - inicio
end

# Medir operaciones individuales
tiempos = {
  "Crear Array vacío" => medir_tiempo_ns { Array.new },
  "Crear Hash vacío" => medir_tiempo_ns { Hash.new },
  "Crear String" => medir_tiempo_ns { String.new("hola") },
  "Sumar integers" => medir_tiempo_ns { 1 + 2 + 3 + 4 + 5 }
}

tiempos.each do |operacion, nanos|
  puts "  #{operacion}: #{nanos} ns"
end

# ──────────────────────────────────────────────────────────────────────────────
# 5. Simulación de Benchmark.ips (iteraciones por segundo)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 5. Iteraciones por segundo (estilo benchmark-ips) ──"

# benchmark-ips es una gema popular. Aquí simulamos su comportamiento básico.
# Para proyectos reales, usar: gem install benchmark-ips

def medir_ips(nombre:, duracion: 1.0)
  conteo = 0
  inicio = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  loop do
    yield
    conteo += 1
    ahora = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    break if (ahora - inicio) >= duracion
  end

  tiempo_total = Process.clock_gettime(Process::CLOCK_MONOTONIC) - inicio
  ips = conteo / tiempo_total

  formato = if ips >= 1_000_000
              "#{(ips / 1_000_000).round(2)}M"
            elsif ips >= 1_000
              "#{(ips / 1_000).round(2)}k"
            else
              ips.round(2).to_s
            end

  puts "  #{nombre.ljust(30)} #{formato} i/s (#{conteo} iteraciones en #{tiempo_total.round(2)}s)"
  ips
end

puts "  Comparando concatenación de strings (1 segundo cada uno):"
puts ""

ips_plus = medir_ips(nombre: "String #+") { "hola" + " " + "mundo" }
ips_interp = medir_ips(nombre: 'String interpolación') do
  hola = "hola"
  mundo = "mundo"
  "#{hola} #{mundo}"
end
ips_concat = medir_ips(nombre: "String #<<") do
  str = +""  # String mutable (unfrozen)
  str << "hola"
  str << " "
  str << "mundo"
end

puts ""
ganador = { "+" => ips_plus, "interpolación" => ips_interp, "<<" => ips_concat }.max_by { |_k, val| val }
puts "  🏆 Ganador: #{ganador[0]}"

# ──────────────────────────────────────────────────────────────────────────────
# 6. Frozen vs Unfrozen Strings
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 6. Frozen vs Unfrozen Strings ──"

puts "  Con '# frozen_string_literal: true', los strings literales son frozen."
puts "  Esto ahorra memoria (reutiliza objetos) y es más rápido."
puts ""

Benchmark.bm(20) do |bench|
  bench.report("frozen literal:") do
    500_000.times { "constante" }
  end

  bench.report("String.new (mutable):") do
    500_000.times { String.new("constante") }
  end

  bench.report("+\"\" (unfreeze):") do
    500_000.times { +"constante" }
  end
end

# Verificar que los strings frozen comparten object_id
str_a = "ejemplo"
str_b = "ejemplo"
puts ""
puts "  str_a.object_id: #{str_a.object_id}"
puts "  str_b.object_id: #{str_b.object_id}"
puts "  ¿Mismo objeto?: #{str_a.object_id == str_b.object_id} (frozen_string_literal: true)"

# ──────────────────────────────────────────────────────────────────────────────
# 7. ObjectSpace - Medición de memoria
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 7. ObjectSpace (uso de memoria) ──"

require "objspace"

# Contar objetos por tipo
puts "  Objetos vivos en el runtime:"
conteos = ObjectSpace.count_objects
puts "    Total:   #{conteos[:TOTAL]}"
puts "    Libres:  #{conteos[:FREE]}"
puts "    Strings: #{conteos[:T_STRING]}"
puts "    Arrays:  #{conteos[:T_ARRAY]}"
puts "    Hashes:  #{conteos[:T_HASH]}"

# Medir tamaño de un objeto específico
arreglo_grande = Array.new(1000) { |idx| "elemento_#{idx}" }
tamano = ObjectSpace.memsize_of(arreglo_grande)
puts ""
puts "  Tamaño de un Array de 1000 strings: #{tamano} bytes"

# Medir memoria antes y después de una operación
def medir_memoria_objetos
  GC.start # Forzar recolección de basura para medición más limpia
  antes = ObjectSpace.count_objects[:T_STRING]
  yield
  GC.start
  despues = ObjectSpace.count_objects[:T_STRING]
  despues - antes
end

nuevos_strings = medir_memoria_objetos do
  1000.times.map { |idx| "string_#{idx}" }
end
puts "  Strings creados en operación: ~#{nuevos_strings}"

# ──────────────────────────────────────────────────────────────────────────────
# 8. Comparación práctica: Algoritmos de ordenamiento
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 8. Comparación de algoritmos ──"

# Bubble Sort (O(n²)) vs Array#sort (Quicksort/Timsort, O(n log n))
def bubble_sort(arreglo)
  arr = arreglo.dup
  longitud = arr.length
  loop do
    intercambios = false
    (longitud - 1).times do |idx|
      if arr[idx] > arr[idx + 1]
        arr[idx], arr[idx + 1] = arr[idx + 1], arr[idx]
        intercambios = true
      end
    end
    break unless intercambios
  end
  arr
end

tamanos = [100, 500, 1000]

tamanos.each do |tam|
  datos = Array.new(tam) { rand(10_000) }
  puts ""
  puts "  Array de #{tam} elementos:"

  Benchmark.bm(18) do |bench|
    bench.report("  bubble_sort:") { bubble_sort(datos) }
    bench.report("  Array#sort:") { datos.sort }
    bench.report("  Array#sort_by:") { datos.sort_by { |val| val } }
  end
end

# ──────────────────────────────────────────────────────────────────────────────
# 9. Comparación: Acceso a elementos
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 9. Comparación de estructuras para acceso ──"

num_elementos = 10_000

# Preparar estructuras
arr_pares = (1..num_elementos).map { |idx| [:"key_#{idx}", idx] }
hash_datos = arr_pares.to_h
struct_type = Struct.new(*arr_pares.first(100).map(&:first))

puts ""
Benchmark.bm(20) do |bench|
  bench.report("Hash#[]") do
    100_000.times { hash_datos[:key_5000] }
  end

  bench.report("Hash#fetch") do
    100_000.times { hash_datos.fetch(:key_5000) }
  end

  bench.report("Hash#dig") do
    nested = { nivel1: { nivel2: { nivel3: "valor" } } }
    100_000.times { nested.dig(:nivel1, :nivel2, :nivel3) }
  end
end

# ──────────────────────────────────────────────────────────────────────────────
# 10. Resumen y consejos
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 10. Resumen y consejos ──"

puts <<~CONSEJOS
  ✅ Buenas prácticas de benchmarking:
     • Usar Benchmark.bmbm para mediciones más estables (warm-up)
     • Medir operaciones realistas, no micro-benchmarks aislados
     • Considerar la gema 'benchmark-ips' para iteraciones/segundo
     • Forzar GC antes de medir memoria (GC.start)
     • Usar Process.clock_gettime(:CLOCK_MONOTONIC) en vez de Time.now

  📊 Resultados típicos en Ruby:
     • Set/Hash lookup >> Array#include? para colecciones grandes
     • String interpolación ≈ String#+ (ambos rápidos)
     • String#<< es más eficiente para concatenación acumulativa
     • Frozen strings ahorran memoria (reutilizan objetos)
     • Array#sort (C) >> cualquier sort implementado en Ruby puro

  🔧 Herramientas avanzadas (gemas):
     • benchmark-ips    → Iteraciones por segundo con warm-up automático
     • memory_profiler  → Análisis detallado de asignación de memoria
     • stackprof        → Profiling de CPU (sampling)
     • ruby-prof        → Profiling detallado (instrumentación)
     • derailed_benchmarks → Benchmarks para aplicaciones Rails
CONSEJOS

puts "✅ Archivo 02_benchmarks_y_profiling.rb ejecutado correctamente"
