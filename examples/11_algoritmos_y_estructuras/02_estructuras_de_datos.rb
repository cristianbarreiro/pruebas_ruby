# frozen_string_literal: true

# = Estructuras de Datos
#
# Este ejemplo implementa Stack, Queue, LinkedList con clases,
# explica Hash maps y Sets, y muestra detección de duplicados,
# agrupamiento y transformación de datos. Cada estructura incluye
# un caso de uso práctico.

# ─────────────────────────────────────────────
# Sección 1: Stack (Pila) — LIFO (Last In, First Out)
# ─────────────────────────────────────────────
# Caso de uso: verificar paréntesis balanceados, deshacer/rehacer,
# evaluación de expresiones postfijas.

class Stack
  def initialize
    @elements = []
  end

  def push(element)
    @elements.push(element)
    self # Permite encadenamiento: stack.push(1).push(2)
  end

  def pop
    raise "Stack vacío: no se puede hacer pop" if empty?

    @elements.pop
  end

  # Mirar el elemento del tope sin removerlo
  def peek
    raise "Stack vacío: no se puede hacer peek" if empty?

    @elements.last
  end

  def empty?
    @elements.empty?
  end

  def size
    @elements.size
  end

  def to_s
    "Stack(#{@elements.inspect}, tope=#{empty? ? 'nil' : @elements.last.inspect})"
  end

  def inspect
    to_s
  end
end

# Caso de uso práctico: verificar paréntesis balanceados
def parentesis_balanceados?(texto)
  pila = Stack.new
  pares = { ")" => "(", "]" => "[", "}" => "{" }
  apertura = pares.values

  texto.each_char do |char|
    if apertura.include?(char)
      pila.push(char)
    elsif pares.key?(char)
      return false if pila.empty?
      return false if pila.pop != pares[char]
    end
  end

  pila.empty?
end

# ─────────────────────────────────────────────
# Sección 2: Queue (Cola) — FIFO (First In, First Out)
# ─────────────────────────────────────────────
# Caso de uso: procesamiento de tareas, BFS (búsqueda en anchura),
# cola de impresión, buffer de mensajes.

class Queue
  def initialize
    @elements = []
  end

  def enqueue(element)
    @elements.push(element)
    self
  end

  # También conocido como "dequeue"
  def dequeue
    raise "Queue vacía: no se puede hacer dequeue" if empty?

    @elements.shift
  end

  # Mirar el primer elemento sin removerlo
  def front
    raise "Queue vacía" if empty?

    @elements.first
  end

  def empty?
    @elements.empty?
  end

  def size
    @elements.size
  end

  def to_s
    "Queue(#{@elements.inspect}, frente=#{empty? ? 'nil' : @elements.first.inspect})"
  end

  def inspect
    to_s
  end
end

# ⚠️ Nota de rendimiento: Array#shift es O(n) porque desplaza todos los elementos.
# Para colas de alto rendimiento, usar una implementación con dos stacks o un ring buffer.
# Ruby tiene Thread::Queue para concurrencia, que es más eficiente.

# Caso de uso práctico: procesador de tareas con prioridad simple
def demo_procesador_tareas
  puts "--- Caso de uso: Procesador de tareas ---"
  cola = Queue.new

  # Simular llegada de tareas
  tareas = ["Enviar email", "Generar reporte", "Backup de BD", "Notificar usuario"]
  tareas.each { |tarea| cola.enqueue(tarea) }

  puts "Tareas en cola: #{cola.size}"

  # Procesar en orden de llegada (FIFO)
  while !cola.empty?
    tarea = cola.dequeue
    puts "  Procesando: #{tarea} ✓"
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 3: LinkedList (Lista enlazada)
# ─────────────────────────────────────────────
# Caso de uso: inserciones/eliminaciones frecuentes al inicio,
# implementación de otras estructuras (stacks, queues),
# cuando no se necesita acceso aleatorio.

class LinkedListNode
  attr_accessor :value, :next_node

  def initialize(value, next_node: nil)
    @value = value
    @next_node = next_node
  end
end

class LinkedList
  include Enumerable

  attr_reader :size

  def initialize
    @head = nil
    @size = 0
  end

  # Agregar al inicio — O(1)
  def prepend(value)
    @head = LinkedListNode.new(value, next_node: @head)
    @size += 1
    self
  end

  # Agregar al final — O(n) (debemos recorrer toda la lista)
  def append(value)
    new_node = LinkedListNode.new(value)

    if @head.nil?
      @head = new_node
    else
      current = @head
      current = current.next_node while current.next_node
      current.next_node = new_node
    end

    @size += 1
    self
  end

  # Eliminar la primera ocurrencia de un valor — O(n)
  def delete(value)
    return nil if @head.nil?

    if @head.value == value
      removed = @head
      @head = @head.next_node
      @size -= 1
      return removed.value
    end

    current = @head
    while current.next_node
      if current.next_node.value == value
        removed = current.next_node
        current.next_node = removed.next_node
        @size -= 1
        return removed.value
      end
      current = current.next_node
    end

    nil # No encontrado
  end

  # Buscar un valor — O(n)
  def find(value)
    current = @head
    while current
      return current.value if current.value == value

      current = current.next_node
    end
    nil
  end

  # Incluir? — O(n)
  def include?(value)
    !find(value).nil?
  end

  # Implementación de each para Enumerable — O(n)
  def each(&block)
    return to_enum(:each) unless block_given?

    current = @head
    while current
      block.call(current.value)
      current = current.next_node
    end
  end

  def empty?
    @head.nil?
  end

  def first
    @head&.value
  end

  def to_s
    values = map(&:to_s).join(" → ")
    "LinkedList[#{values}]"
  end

  def inspect
    to_s
  end
end

# ─────────────────────────────────────────────
# Sección 4: Hash maps — Diccionarios en Ruby
# ─────────────────────────────────────────────
# Ruby Hash es una implementación de hash map (tabla hash).
# Complejidad promedio: O(1) para lectura, escritura y eliminación.
# Desde Ruby 1.9, los Hash mantienen el orden de inserción.

def demo_hash_maps
  puts "=== Hash maps (Diccionarios) ==="

  # Creación y operaciones básicas
  inventario = { "manzanas" => 50, "bananas" => 30, "naranjas" => 45 }
  puts "Inventario: #{inventario}"

  # Acceso — O(1) promedio
  puts "Manzanas: #{inventario['manzanas']}"

  # Acceso seguro con fetch (lanza error si no existe, o usa default)
  puts "Peras: #{inventario.fetch('peras', 0)}"

  # Operaciones comunes
  inventario["uvas"] = 25                   # Agregar — O(1)
  inventario.delete("bananas")              # Eliminar — O(1)
  puts "¿Tiene naranjas?: #{inventario.key?('naranjas')}"  # Verificar — O(1)

  # Iterar
  puts "Inventario actualizado:"
  inventario.each { |fruta, cantidad| puts "  #{fruta}: #{cantidad} unidades" }

  # Métodos útiles
  puts "Claves:  #{inventario.keys}"
  puts "Valores: #{inventario.values}"
  puts "Total unidades: #{inventario.values.sum}"
  puts "Fruta con más stock: #{inventario.max_by { |_key, val| val }&.first}"

  # Default value — evita nil para claves no existentes
  conteo = Hash.new(0)
  "hello world".each_char { |char| conteo[char] += 1 }
  puts "\nFrecuencia de letras en 'hello world':"
  conteo.sort_by { |_char, cnt| -cnt }.each { |char, cnt| puts "  '#{char}': #{cnt}" }

  # Default con bloque (cada clave obtiene un objeto independiente)
  agrupado = Hash.new { |hsh, key| hsh[key] = [] }
  [["fruta", "manzana"], ["verdura", "zanahoria"], ["fruta", "pera"], ["verdura", "brócoli"]].each do |cat, item|
    agrupado[cat] << item
  end
  puts "\nAgrupado: #{agrupado}"

  # ⚠️ Error común: Hash.new([]) comparte el MISMO array entre todas las claves
  malo = Hash.new([])
  malo[:lista_a] << "item1"
  malo[:lista_b] << "item2"
  puts "\n⚠️  Hash.new([]) comparte arrays: #{malo[:lista_a].inspect}"
  puts "   Todos apuntan al mismo objeto. Usar Hash.new { |h, k| h[k] = [] } en su lugar."
  puts
end

# ─────────────────────────────────────────────
# Sección 5: Sets — Conjuntos
# ─────────────────────────────────────────────
# Set es una colección de valores únicos, sin orden garantizado.
# Internamente usa un Hash, por lo que las operaciones son O(1) promedio.

require "set"

def demo_sets
  puts "=== Sets (Conjuntos) ==="

  # Creación
  frutas = Set.new(["manzana", "banana", "naranja", "manzana"])  # Duplicados eliminados
  puts "Set de frutas: #{frutas.inspect}"
  puts "Tamaño: #{frutas.size}"  # => 3 (manzana aparece solo una vez)

  # Operaciones básicas — O(1) promedio
  frutas.add("uva")
  frutas.delete("banana")
  puts "¿Tiene manzana?: #{frutas.include?('manzana')}"

  # Operaciones de conjuntos
  tropicales = Set.new(["mango", "papaya", "banana", "naranja"])

  puts "\nFrutas: #{frutas.inspect}"
  puts "Tropicales: #{tropicales.inspect}"
  puts "Unión (|):       #{(frutas | tropicales).inspect}"
  puts "Intersección (&): #{(frutas & tropicales).inspect}"
  puts "Diferencia (-):   #{(frutas - tropicales).inspect}"
  puts "Diferencia simétrica (^): #{(frutas ^ tropicales).inspect}"

  # Subconjuntos y superconjuntos
  pequeño = Set.new(["manzana", "naranja"])
  puts "\n#{pequeño.inspect} ⊂ #{frutas.inspect}?: #{pequeño.subset?(frutas)}"
  puts "#{frutas.inspect} ⊃ #{pequeño.inspect}?: #{frutas.superset?(pequeño)}"
  puts
end

# ─────────────────────────────────────────────
# Sección 6: Detección de duplicados
# ─────────────────────────────────────────────

def demo_deteccion_duplicados
  puts "=== Detección de duplicados ==="

  datos = [1, 3, 5, 3, 7, 1, 8, 5, 9, 3]

  # Método 1: Usando Set — O(n)
  vistos = Set.new
  duplicados_set = []
  datos.each do |elem|
    if vistos.include?(elem)
      duplicados_set << elem unless duplicados_set.include?(elem)
    else
      vistos.add(elem)
    end
  end
  puts "Duplicados (Set):   #{duplicados_set.inspect}"

  # Método 2: Usando tally — O(n) (Ruby 2.7+)
  duplicados_tally = datos.tally.select { |_val, cnt| cnt > 1 }.keys
  puts "Duplicados (tally): #{duplicados_tally.inspect}"

  # Método 3: Usando group_by — O(n)
  duplicados_group = datos.group_by(&:itself).select { |_val, arr| arr.size > 1 }.keys
  puts "Duplicados (group): #{duplicados_group.inspect}"

  # Método 4: Comparar con uniq — simple pero O(n)
  tiene_duplicados = datos.size != datos.uniq.size
  puts "¿Tiene duplicados?: #{tiene_duplicados}"

  # Encontrar el primer duplicado — O(n) tiempo, O(n) espacio
  primer_duplicado = nil
  vistos_rapido = Set.new
  datos.each do |elem|
    if vistos_rapido.include?(elem)
      primer_duplicado = elem
      break
    end
    vistos_rapido.add(elem)
  end
  puts "Primer duplicado: #{primer_duplicado}"
  puts
end

# ─────────────────────────────────────────────
# Sección 7: Agrupamiento y transformación de datos
# ─────────────────────────────────────────────

def demo_agrupamiento_transformacion
  puts "=== Agrupamiento y transformación de datos ==="

  # Datos de ejemplo: ventas de una tienda
  ventas = [
    { producto: "Laptop", categoria: "Electrónica", precio: 1200, fecha: "2025-01" },
    { producto: "Mouse", categoria: "Electrónica", precio: 25, fecha: "2025-01" },
    { producto: "Silla", categoria: "Muebles", precio: 350, fecha: "2025-01" },
    { producto: "Monitor", categoria: "Electrónica", precio: 450, fecha: "2025-02" },
    { producto: "Escritorio", categoria: "Muebles", precio: 600, fecha: "2025-02" },
    { producto: "Teclado", categoria: "Electrónica", precio: 75, fecha: "2025-02" },
    { producto: "Lámpara", categoria: "Muebles", precio: 80, fecha: "2025-01" }
  ]

  # Agrupar por categoría
  por_categoria = ventas.group_by { |venta| venta[:categoria] }
  puts "Ventas por categoría:"
  por_categoria.each do |cat, items|
    total = items.sum { |item| item[:precio] }
    puts "  #{cat}: #{items.size} productos, total $#{total}"
  end

  # Agrupar por mes
  por_mes = ventas.group_by { |venta| venta[:fecha] }
  puts "\nVentas por mes:"
  por_mes.each do |mes, items|
    total = items.sum { |item| item[:precio] }
    puts "  #{mes}: #{items.size} ventas, total $#{total}"
  end

  # Transformación: crear un resumen
  resumen = por_categoria.transform_values do |items|
    {
      cantidad: items.size,
      total: items.sum { |item| item[:precio] },
      promedio: (items.sum { |item| item[:precio] }.to_f / items.size).round(2),
      productos: items.map { |item| item[:producto] }
    }
  end
  puts "\nResumen por categoría:"
  resumen.each do |cat, info|
    puts "  #{cat}:"
    puts "    Cantidad: #{info[:cantidad]}"
    puts "    Total:    $#{info[:total]}"
    puts "    Promedio: $#{info[:promedio]}"
    puts "    Items:    #{info[:productos].join(', ')}"
  end

  # Top N productos más caros
  top3 = ventas.max_by(3) { |venta| venta[:precio] }
  puts "\nTop 3 productos más caros:"
  top3.each { |venta| puts "  #{venta[:producto]}: $#{venta[:precio]}" }

  # Pivote: categoría × mes
  puts "\nTabla pivote (categoría × mes):"
  puts "  #{'Categoría'.ljust(15)} | #{'2025-01'.rjust(10)} | #{'2025-02'.rjust(10)}"
  puts "  #{'-' * 15}-+-#{'-' * 10}-+-#{'-' * 10}"
  por_categoria.each do |cat, items|
    mes_01 = items.select { |item| item[:fecha] == "2025-01" }.sum { |item| item[:precio] }
    mes_02 = items.select { |item| item[:fecha] == "2025-02" }.sum { |item| item[:precio] }
    puts "  #{cat.ljust(15)} | $#{mes_01.to_s.rjust(9)} | $#{mes_02.to_s.rjust(9)}"
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 8: Pruebas de las estructuras
# ─────────────────────────────────────────────

def ejecutar_pruebas_estructuras
  puts "=== Pruebas de estructuras de datos ==="
  errores = []

  verificar = ->(nombre, actual, esperado) {
    if actual == esperado
      puts "  ✓ #{nombre}"
    else
      msg = "  ✗ #{nombre}: esperado #{esperado.inspect}, obtuvo #{actual.inspect}"
      puts msg
      errores << msg
    end
  }

  # --- Stack ---
  puts "\n--- Stack ---"
  pila = Stack.new
  verificar.call("Stack vacío", pila.empty?, true)
  verificar.call("Size vacío", pila.size, 0)

  pila.push(10).push(20).push(30)
  verificar.call("Size después de push", pila.size, 3)
  verificar.call("Peek", pila.peek, 30)
  verificar.call("Pop", pila.pop, 30)
  verificar.call("Pop siguiente", pila.pop, 20)
  verificar.call("Size después de pop", pila.size, 1)

  begin
    Stack.new.pop
    verificar.call("Pop en vacío lanza error", false, true)
  rescue RuntimeError
    verificar.call("Pop en vacío lanza error", true, true)
  end

  # --- Paréntesis balanceados ---
  puts "\n--- Paréntesis balanceados (Stack) ---"
  verificar.call("'()'", parentesis_balanceados?("()"), true)
  verificar.call("'()[]{}'", parentesis_balanceados?("()[]{}"), true)
  verificar.call("'{[()]}'", parentesis_balanceados?("{[()]}"), true)
  verificar.call("'(]'", parentesis_balanceados?("(]"), false)
  verificar.call("'([)]'", parentesis_balanceados?("([)]"), false)
  verificar.call("Vacío", parentesis_balanceados?(""), true)
  verificar.call("'a + (b * [c - d])'", parentesis_balanceados?("a + (b * [c - d])"), true)

  # --- Queue ---
  puts "\n--- Queue ---"
  cola = Queue.new
  verificar.call("Queue vacía", cola.empty?, true)

  cola.enqueue("A").enqueue("B").enqueue("C")
  verificar.call("Size", cola.size, 3)
  verificar.call("Front", cola.front, "A")
  verificar.call("Dequeue", cola.dequeue, "A")
  verificar.call("Dequeue siguiente", cola.dequeue, "B")
  verificar.call("Size después", cola.size, 1)

  begin
    Queue.new.dequeue
    verificar.call("Dequeue en vacía lanza error", false, true)
  rescue RuntimeError
    verificar.call("Dequeue en vacía lanza error", true, true)
  end

  # --- LinkedList ---
  puts "\n--- LinkedList ---"
  lista = LinkedList.new
  verificar.call("Lista vacía", lista.empty?, true)
  verificar.call("Size vacía", lista.size, 0)

  lista.append(10).append(20).append(30)
  verificar.call("Size después de append", lista.size, 3)
  verificar.call("First", lista.first, 10)
  verificar.call("Include 20", lista.include?(20), true)
  verificar.call("Include 99", lista.include?(99), false)
  verificar.call("Find 20", lista.find(20), 20)
  verificar.call("Find 99", lista.find(99), nil)

  # to_a funciona gracias a Enumerable
  verificar.call("to_a", lista.to_a, [10, 20, 30])

  # Prepend
  lista.prepend(5)
  verificar.call("Prepend", lista.first, 5)
  verificar.call("to_a con prepend", lista.to_a, [5, 10, 20, 30])

  # Delete
  lista.delete(20)
  verificar.call("Delete medio", lista.to_a, [5, 10, 30])
  lista.delete(5)
  verificar.call("Delete inicio", lista.to_a, [10, 30])
  lista.delete(30)
  verificar.call("Delete final", lista.to_a, [10])
  verificar.call("Delete no existente", lista.delete(999), nil)

  # Enumerable methods
  lista_enum = LinkedList.new
  lista_enum.append(3).append(1).append(4).append(1).append(5)
  verificar.call("min", lista_enum.min, 1)
  verificar.call("max", lista_enum.max, 5)
  verificar.call("select", lista_enum.select { |val| val > 2 }, [3, 4, 5])
  verificar.call("map * 2", lista_enum.map { |val| val * 2 }, [6, 2, 8, 2, 10])
  verificar.call("sum", lista_enum.sum, 14)

  # --- Resumen ---
  puts "\n#{'=' * 40}"
  if errores.empty?
    puts "✅ Todas las pruebas pasaron."
  else
    puts "❌ #{errores.size} prueba(s) fallaron:"
    errores.each { |err| puts err }
  end
  puts
end

# ─────────────────────────────────────────────
# Ejecución principal
# ─────────────────────────────────────────────

ejecutar_pruebas_estructuras
demo_procesador_tareas
demo_hash_maps
demo_sets
demo_deteccion_duplicados
demo_agrupamiento_transformacion

puts "=" * 60
puts "Todos los demos de estructuras de datos completados."
