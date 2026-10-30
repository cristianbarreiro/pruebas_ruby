# frozen_string_literal: true

# = Búsqueda y Ordenamiento
#
# Este ejemplo implementa algoritmos clásicos de búsqueda y ordenamiento,
# analiza su complejidad Big O, los compara con la stdlib de Ruby,
# e incluye pruebas con arrays vacíos, un solo elemento y duplicados.

# ─────────────────────────────────────────────
# Sección 1: Búsqueda lineal
# ─────────────────────────────────────────────
# Complejidad: O(n) en el peor caso, O(1) en el mejor caso.
# Funciona con arrays ordenados y desordenados.
# Es la opción correcta cuando el array no está ordenado o es muy pequeño.

def busqueda_lineal(arr, objetivo)
  arr.each_with_index do |elemento, idx|
    return idx if elemento == objetivo
  end
  nil # No encontrado
end

# Variante: buscar todos los índices de un valor (útil con duplicados)
def busqueda_lineal_todos(arr, objetivo)
  indices = []
  arr.each_with_index do |elemento, idx|
    indices << idx if elemento == objetivo
  end
  indices
end

# ─────────────────────────────────────────────
# Sección 2: Búsqueda binaria
# ─────────────────────────────────────────────
# Complejidad: O(log n) en el peor caso.
# ⚠️ REQUIERE que el array esté ordenado.
# En cada paso descarta la mitad de los elementos.

# Versión iterativa (más eficiente en memoria, sin overhead de recursión)
def busqueda_binaria(arr, objetivo)
  izq = 0
  der = arr.length - 1

  while izq <= der
    medio = izq + ((der - izq) / 2) # Evita overflow en otros lenguajes (buena práctica)
    valor_medio = arr[medio]

    if valor_medio == objetivo
      return medio
    elsif valor_medio < objetivo
      izq = medio + 1
    else
      der = medio - 1
    end
  end

  nil # No encontrado
end

# Versión recursiva (más elegante, pero usa stack space O(log n))
def busqueda_binaria_recursiva(arr, objetivo, izq = 0, der = nil)
  der = arr.length - 1 if der.nil?
  return nil if izq > der

  medio = izq + ((der - izq) / 2)

  case objetivo <=> arr[medio]
  when 0  then medio # Encontrado
  when 1  then busqueda_binaria_recursiva(arr, objetivo, medio + 1, der)  # Buscar en mitad derecha
  when -1 then busqueda_binaria_recursiva(arr, objetivo, izq, medio - 1)  # Buscar en mitad izquierda
  end
end

# ─────────────────────────────────────────────
# Sección 3: Bubble Sort
# ─────────────────────────────────────────────
# Complejidad: O(n²) promedio y peor caso, O(n) mejor caso (ya ordenado con flag).
# Fácil de entender pero ineficiente para arrays grandes.
# Útil solo para enseñanza o arrays muy pequeños (< 20 elementos).

def bubble_sort(arr)
  resultado = arr.dup # No modificar el array original
  largo = resultado.length

  (largo - 1).times do |idx|
    hubo_intercambio = false

    (0...(largo - 1 - idx)).each do |jdx|
      if resultado[jdx] > resultado[jdx + 1]
        resultado[jdx], resultado[jdx + 1] = resultado[jdx + 1], resultado[jdx]
        hubo_intercambio = true
      end
    end

    # Optimización: si no hubo intercambios, el array ya está ordenado
    break unless hubo_intercambio
  end

  resultado
end

# ─────────────────────────────────────────────
# Sección 4: Merge Sort
# ─────────────────────────────────────────────
# Complejidad: O(n log n) en TODOS los casos (mejor, promedio y peor).
# Es un algoritmo estable (preserva el orden relativo de elementos iguales).
# Desventaja: usa O(n) de memoria adicional para las copias.
# Es el algoritmo base de muchas implementaciones de sort en lenguajes modernos.

def merge_sort(arr)
  return arr.dup if arr.length <= 1

  medio = arr.length / 2
  izquierda = merge_sort(arr[0...medio])
  derecha = merge_sort(arr[medio..])

  merge(izquierda, derecha)
end

# Función auxiliar que combina dos arrays ordenados en uno solo ordenado.
# Complejidad: O(n + m) donde n y m son los tamaños de los arrays.
def merge(izq, der)
  resultado = []
  idx_izq = 0
  idx_der = 0

  while idx_izq < izq.length && idx_der < der.length
    if izq[idx_izq] <= der[idx_der]
      resultado << izq[idx_izq]
      idx_izq += 1
    else
      resultado << der[idx_der]
      idx_der += 1
    end
  end

  # Agregar los elementos restantes
  resultado.concat(izq[idx_izq..]) if idx_izq < izq.length
  resultado.concat(der[idx_der..]) if idx_der < der.length
  resultado
end

# ─────────────────────────────────────────────
# Sección 5: Recursión — Ejemplos clásicos
# ─────────────────────────────────────────────

# Factorial — O(n)
# ⚠️ Ruby no optimiza tail recursion por defecto.
# Para valores grandes, preferir la versión iterativa.
def factorial(num)
  raise ArgumentError, "El número debe ser no negativo" if num.negative?
  return 1 if num <= 1

  num * factorial(num - 1)
end

# Fibonacci — O(2^n) versión naive ⚠️ MUY LENTO para n > 30
def fibonacci_naive(num)
  return num if num <= 1

  fibonacci_naive(num - 1) + fibonacci_naive(num - 2)
end

# Fibonacci — O(n) con memoización (programación dinámica top-down)
def fibonacci_memo(num, cache = {})
  return num if num <= 1
  return cache[num] if cache.key?(num)

  cache[num] = fibonacci_memo(num - 1, cache) + fibonacci_memo(num - 2, cache)
end

# Fibonacci — O(n) iterativo (más eficiente, sin overhead de recursión)
def fibonacci_iterativo(num)
  return num if num <= 1

  prev = 0
  curr = 1
  (num - 1).times do
    prev, curr = curr, prev + curr
  end
  curr
end

# ─────────────────────────────────────────────
# Sección 6: Comparación con la stdlib de Ruby
# ─────────────────────────────────────────────

def demo_comparacion_stdlib
  puts "=== Comparación con la stdlib de Ruby ==="

  arr = [64, 34, 25, 12, 22, 11, 90, 1, 55, 42]

  # Ruby usa una variante de Timsort (híbrido merge sort + insertion sort)
  # Complejidad: O(n log n)
  ordenado_stdlib = arr.sort
  puts "Array original:  #{arr.inspect}"
  puts "sort (stdlib):   #{ordenado_stdlib.inspect}"

  # sort con bloque personalizado
  por_ultimo_digito = arr.sort_by { |num| num % 10 }
  puts "sort_by último dígito: #{por_ultimo_digito.inspect}"

  # sort! modifica en lugar (in-place)
  copia = arr.dup
  copia.sort!
  puts "sort! (in-place): #{copia.inspect}"

  # Nuestras implementaciones
  puts "\nBubble sort: #{bubble_sort(arr).inspect}"
  puts "Merge sort:  #{merge_sort(arr).inspect}"

  # bsearch — búsqueda binaria de la stdlib
  # ⚠️ El array DEBE estar ordenado
  ordenado = arr.sort
  puts "\n--- bsearch de la stdlib ---"
  puts "Array ordenado: #{ordenado.inspect}"

  # bsearch con bloque de comparación (find-minimum mode)
  resultado = ordenado.bsearch { |val| val >= 25 }
  puts "Primer elemento >= 25: #{resultado}"

  # bsearch con bloque de comparación (find-any mode)
  indice = ordenado.bsearch_index { |val| val >= 42 }
  puts "Índice del primer >= 42: #{indice}"

  # Nuestra búsqueda binaria
  puts "Búsqueda binaria de 42: índice #{busqueda_binaria(ordenado, 42)}"
  puts "Búsqueda lineal de 42:  índice #{busqueda_lineal(ordenado, 42)}"
  puts
end

# ─────────────────────────────────────────────
# Sección 7: Pruebas con casos edge
# ─────────────────────────────────────────────

def ejecutar_pruebas
  puts "=== Pruebas con casos edge ==="

  errores = []

  # --- Helper para verificar resultados ---
  verificar = lambda { |nombre, actual, esperado|
    if actual == esperado
      puts "  ✓ #{nombre}"
    else
      msg = "  ✗ #{nombre}: esperado #{esperado.inspect}, obtuvo #{actual.inspect}"
      puts msg
      errores << msg
    end
  }

  # --- Pruebas de búsqueda lineal ---
  puts "\n--- Búsqueda lineal ---"
  verificar.call("Array vacío", busqueda_lineal([], 5), nil)
  verificar.call("Un elemento (encontrado)", busqueda_lineal([7], 7), 0)
  verificar.call("Un elemento (no encontrado)", busqueda_lineal([7], 3), nil)
  verificar.call("Múltiples elementos", busqueda_lineal([10, 20, 30, 40], 30), 2)
  verificar.call("Duplicados (retorna primero)", busqueda_lineal([1, 2, 2, 3], 2), 1)
  verificar.call("Elemento al final", busqueda_lineal([1, 2, 3, 4, 5], 5), 4)
  verificar.call("Todos los índices", busqueda_lineal_todos([1, 3, 5, 3, 7, 3], 3), [1, 3, 5])

  # --- Pruebas de búsqueda binaria ---
  puts "\n--- Búsqueda binaria ---"
  verificar.call("Array vacío", busqueda_binaria([], 5), nil)
  verificar.call("Un elemento (encontrado)", busqueda_binaria([7], 7), 0)
  verificar.call("Un elemento (no encontrado)", busqueda_binaria([7], 3), nil)
  verificar.call("Múltiples elementos", busqueda_binaria([10, 20, 30, 40, 50], 30), 2)
  verificar.call("Primer elemento", busqueda_binaria([10, 20, 30], 10), 0)
  verificar.call("Último elemento", busqueda_binaria([10, 20, 30], 30), 2)
  verificar.call("No existe (menor)", busqueda_binaria([10, 20, 30], 5), nil)
  verificar.call("No existe (mayor)", busqueda_binaria([10, 20, 30], 35), nil)

  # --- Pruebas de búsqueda binaria recursiva ---
  puts "\n--- Búsqueda binaria recursiva ---"
  verificar.call("Array vacío", busqueda_binaria_recursiva([], 5), nil)
  verificar.call("Encontrado", busqueda_binaria_recursiva([1, 3, 5, 7, 9], 5), 2)
  verificar.call("No encontrado", busqueda_binaria_recursiva([1, 3, 5, 7, 9], 4), nil)

  # --- Pruebas de Bubble Sort ---
  puts "\n--- Bubble Sort ---"
  verificar.call("Array vacío", bubble_sort([]), [])
  verificar.call("Un elemento", bubble_sort([42]), [42])
  verificar.call("Ya ordenado", bubble_sort([1, 2, 3, 4, 5]), [1, 2, 3, 4, 5])
  verificar.call("Orden inverso", bubble_sort([5, 4, 3, 2, 1]), [1, 2, 3, 4, 5])
  verificar.call("Con duplicados", bubble_sort([3, 1, 4, 1, 5, 9, 2, 6, 5]), [1, 1, 2, 3, 4, 5, 5, 6, 9])
  verificar.call("Todos iguales", bubble_sort([7, 7, 7, 7]), [7, 7, 7, 7])
  verificar.call("Negativos", bubble_sort([-3, -1, -4, -1, -5]), [-5, -4, -3, -1, -1])

  # Verificar que no modifica el original
  original = [3, 1, 2]
  bubble_sort(original)
  verificar.call("No modifica original", original, [3, 1, 2])

  # --- Pruebas de Merge Sort ---
  puts "\n--- Merge Sort ---"
  verificar.call("Array vacío", merge_sort([]), [])
  verificar.call("Un elemento", merge_sort([42]), [42])
  verificar.call("Ya ordenado", merge_sort([1, 2, 3, 4, 5]), [1, 2, 3, 4, 5])
  verificar.call("Orden inverso", merge_sort([5, 4, 3, 2, 1]), [1, 2, 3, 4, 5])
  verificar.call("Con duplicados", merge_sort([3, 1, 4, 1, 5, 9, 2, 6, 5]), [1, 1, 2, 3, 4, 5, 5, 6, 9])
  verificar.call("Todos iguales", merge_sort([7, 7, 7, 7]), [7, 7, 7, 7])
  verificar.call("Dos elementos", merge_sort([2, 1]), [1, 2])
  verificar.call("Array grande", merge_sort((1..100).to_a.shuffle), (1..100).to_a)

  # --- Pruebas de recursión ---
  puts "\n--- Factorial ---"
  verificar.call("factorial(0)", factorial(0), 1)
  verificar.call("factorial(1)", factorial(1), 1)
  verificar.call("factorial(5)", factorial(5), 120)
  verificar.call("factorial(10)", factorial(10), 3_628_800)

  begin
    factorial(-1)
    verificar.call("factorial negativo lanza error", false, true)
  rescue ArgumentError
    verificar.call("factorial negativo lanza ArgumentError", true, true)
  end

  puts "\n--- Fibonacci ---"
  verificar.call("fibonacci(0)", fibonacci_memo(0), 0)
  verificar.call("fibonacci(1)", fibonacci_memo(1), 1)
  verificar.call("fibonacci(10)", fibonacci_memo(10), 55)
  verificar.call("fibonacci(20)", fibonacci_memo(20), 6765)
  verificar.call("fibonacci iterativo(20)", fibonacci_iterativo(20), 6765)

  # Verificar que ambas implementaciones dan el mismo resultado
  (0..15).each do |num|
    resultado_memo = fibonacci_memo(num)
    resultado_iter = fibonacci_iterativo(num)
    verificar.call("fib_memo(#{num}) == fib_iter(#{num})", resultado_memo, resultado_iter)
  end

  # --- Resumen ---
  puts "\n#{"=" * 40}"
  if errores.empty?
    puts "✅ Todas las pruebas pasaron."
  else
    puts "❌ #{errores.size} prueba(s) fallaron:"
    errores.each { |err| puts err }
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 8: Análisis de complejidad (resumen)
# ─────────────────────────────────────────────

def demo_analisis_complejidad
  puts "=== Resumen de complejidad Big O ==="
  puts
  puts "  Algoritmo                | Mejor    | Promedio | Peor     | Espacio"
  puts "  ─────────────────────────┼──────────┼──────────┼──────────┼────────"
  puts "  Búsqueda lineal          | O(1)     | O(n)     | O(n)     | O(1)"
  puts "  Búsqueda binaria         | O(1)     | O(log n) | O(log n) | O(1)*"
  puts "  Bubble Sort              | O(n)     | O(n²)    | O(n²)    | O(1)"
  puts "  Merge Sort               | O(n lg n)| O(n lg n)| O(n lg n)| O(n)"
  puts "  Ruby sort (Timsort)      | O(n)     | O(n lg n)| O(n lg n)| O(n)"
  puts
  puts "  * La versión recursiva de búsqueda binaria usa O(log n) de stack."
  puts
  puts "  Regla práctica:"
  puts "    - n < 50:      cualquier algoritmo es suficiente"
  puts "    - n < 1000:    O(n²) todavía es aceptable"
  puts "    - n > 10,000:  necesitas O(n log n) o mejor"
  puts "    - n > 100,000: usa siempre la stdlib (arr.sort, arr.bsearch)"
  puts
end

# ─────────────────────────────────────────────
# Ejecución principal
# ─────────────────────────────────────────────

demo_comparacion_stdlib
ejecutar_pruebas
demo_analisis_complejidad

puts "=" * 60
puts "Todos los demos de búsqueda y ordenamiento completados."
