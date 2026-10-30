# frozen_string_literal: true

# = Enumerable Avanzado
#
# Este ejemplo cubre: incluir Enumerable en clases propias, implementar each,
# lazy enumerators, chunk/slice_when/chunk_while, zip, flat_map, each_cons,
# each_slice, group_by, tally, filter_map y más.

# ─────────────────────────────────────────────
# Sección 1: Incluir Enumerable en clases propias
# ─────────────────────────────────────────────
# Al incluir Enumerable y definir `each`, tu clase obtiene ~50 métodos gratis:
# map, select, reject, reduce, min, max, sort, count, any?, all?, none?, etc.

class Playlist
  include Enumerable
  include Comparable

  attr_reader :name

  def initialize(name)
    @name = name
    @songs = []
  end

  def add_song(title, artist, duration_secs)
    @songs << { title: title, artist: artist, duration: duration_secs }
    self # Permite encadenamiento
  end

  # ⭐ Este es el único método que Enumerable REQUIERE
  def each(&)
    return to_enum(:each) unless block_given?

    @songs.each(&)
  end

  def size
    @songs.size
  end

  # Comparable requiere <=> para obtener <, <=, ==, >=, >, between?
  def <=>(other)
    size <=> other.size
  end

  def total_duration
    sum { |song| song[:duration] }
  end

  def formatted_duration
    total = total_duration
    minutes = total / 60
    seconds = total % 60
    format("%<min>d:%<sec>02d", min: minutes, sec: seconds)
  end

  def to_s
    "Playlist '#{@name}' (#{count} canciones, #{formatted_duration})"
  end
end

def demo_enumerable_en_clase
  puts "=== Enumerable en clases propias ==="

  playlist = Playlist.new("Road Trip")
  playlist
    .add_song("Bohemian Rhapsody", "Queen", 355)
    .add_song("Hotel California", "Eagles", 391)
    .add_song("Stairway to Heaven", "Led Zeppelin", 482)
    .add_song("Imagine", "John Lennon", 187)
    .add_song("Yesterday", "The Beatles", 125)

  puts playlist

  # Todos estos métodos vienen GRATIS por incluir Enumerable
  puts "\nCanciones de más de 5 minutos:"
  playlist.select { |song| song[:duration] > 300 }.each do |song|
    puts "  #{song[:title]} (#{song[:duration]}s)"
  end

  puts "\n¿Alguna canción de Queen?: #{playlist.any? { |song| song[:artist] == "Queen" }}"
  puts "¿Todas > 2 min?: #{playlist.all? { |song| song[:duration] > 120 }}"
  puts "Canción más larga: #{playlist.max_by { |song| song[:duration] }[:title]}"
  puts "Canción más corta: #{playlist.min_by { |song| song[:duration] }[:title]}"
  puts "Duración total: #{playlist.total_duration}s (#{playlist.formatted_duration})"

  # map, reduce
  titulos = playlist.map { |song| song[:title] }
  puts "Títulos: #{titulos.inspect}"

  duracion_total = playlist.reduce(0) { |sum, song| sum + song[:duration] }
  puts "reduce duración: #{duracion_total}s"

  # sort_by
  puts "\nOrdenadas por duración (ascendente):"
  playlist.sort_by { |song| song[:duration] }.each do |song|
    puts "  #{song[:title]}: #{song[:duration]}s"
  end

  # Comparable: comparar playlists por tamaño
  otra = Playlist.new("Corta")
  otra.add_song("Song A", "Artist", 200).add_song("Song B", "Artist", 180)

  puts "\n#{playlist} > #{otra}?: #{playlist > otra}"
  puts [otra, playlist].min
  puts
end

# ─────────────────────────────────────────────
# Sección 2: Custom each con Enumerator
# ─────────────────────────────────────────────
# Cuando `each` se llama sin bloque, debe retornar un Enumerator.
# Esto permite encadenamiento: obj.each.with_index, obj.each.lazy, etc.

class FibonacciSequence
  include Enumerable

  def initialize(limit)
    @limit = limit
  end

  def each
    return to_enum(:each) { @limit } unless block_given? # { @limit } es el size hint

    prev = 0
    curr = 1
    count = 0

    while count < @limit
      yield prev
      prev, curr = curr, prev + curr
      count += 1
    end
  end
end

def demo_custom_each
  puts "=== Custom each con Enumerator ==="

  fib = FibonacciSequence.new(10)
  puts "Fibonacci(10): #{fib.to_a.inspect}"
  puts "Primeros 5 pares: #{fib.select(&:even?).first(5).inspect}"
  puts "Suma: #{fib.sum}"

  # Sin bloque retorna Enumerator (permite encadenamiento)
  enum = fib.each
  puts "Enumerator: #{enum.class}"
  puts "Con índice: #{enum.with_index.first(5).inspect}"

  # Crear Enumerator manualmente con Enumerator.new
  countdown = Enumerator.new do |yielder|
    num = 5
    while num >= 0
      yielder.yield num
      num -= 1
    end
  end
  puts "Countdown: #{countdown.to_a.inspect}"
  puts
end

# ─────────────────────────────────────────────
# Sección 3: Lazy Enumerators
# ─────────────────────────────────────────────
# Los lazy enumerators evalúan los elementos uno a uno, bajo demanda.
# Esenciales para secuencias infinitas o pipelines con datos grandes.

def demo_lazy_enumerators
  puts "=== Lazy Enumerators ==="

  # Sin lazy: esto intentaría crear un array infinito y colgaría el programa
  # (0..Float::INFINITY).select { |n| n.odd? }.first(5) # ❌ NO hacer esto

  # Con lazy: evalúa bajo demanda, solo procesa lo necesario
  primeros_impares = (0..Float::INFINITY).lazy.select(&:odd?).first(5)
  puts "Primeros 5 impares (lazy): #{primeros_impares.inspect}"

  # Pipeline lazy con múltiples transformaciones
  resultado = (1..Float::INFINITY).lazy
              .select(&:odd?)
              .map { |num| num**2 }
              .select { |num| num.to_s.include?("9") }
              .first(5)
  puts "Impares², con dígito 9: #{resultado.inspect}"

  # Lazy es útil para archivos grandes (lectura línea por línea sin cargar todo)
  puts "\nLazy con procesamiento de líneas:"
  lineas = ["error: disco lleno", "info: conexión OK", "warn: latencia alta",
            "error: timeout", "info: backup completo", "error: sin memoria"]

  # Simular lectura lazy de un archivo
  errores = lineas.lazy
                  .select { |linea| linea.start_with?("error:") }
                  .map { |linea| linea.sub("error: ", "").upcase }
                  .first(2)
  puts "Primeros 2 errores: #{errores.inspect}"

  # Comparar eager vs lazy
  puts "\nEager vs Lazy — Orden de evaluación:"
  puts "Eager (procesa TODO, luego toma primeros):"
  eager_selected = [1, 2, 3, 4, 5].select do |num|
    print "  s(#{num})"
    num.even?
  end
  eager_mapped = eager_selected.map do |num|
    print " m(#{num})"
    num * 10
  end
  eager_mapped.first(1)
  puts

  puts "Lazy (procesa uno a uno hasta tener suficientes):"
  lazy_selected = [1, 2, 3, 4, 5].lazy.select do |num|
    print "  s(#{num})"
    num.even?
  end
  lazy_mapped = lazy_selected.map do |num|
    print " m(#{num})"
    num * 10
  end
  lazy_mapped.first(1)
  puts
  puts
end

# ─────────────────────────────────────────────
# Sección 4: chunk, slice_when, chunk_while
# ─────────────────────────────────────────────
# Estos métodos agrupan elementos consecutivos según una condición.

def demo_chunk_y_slicing
  puts "=== chunk, slice_when, chunk_while ==="

  # chunk — agrupa elementos CONSECUTIVOS que retornan el mismo valor del bloque
  temperaturas = [22, 23, 25, 28, 30, 31, 27, 24, 21, 19, 18, 20, 23, 26]

  puts "Temperaturas agrupadas por rango:"
  chunks = temperaturas.chunk do |temp|
    case temp
    when 0...20  then :frio
    when 20...28 then :templado
    else              :caliente
    end
  end
  chunks.each do |tipo, temps|
    puts "  #{tipo}: #{temps.inspect}"
  end

  # chunk_while — agrupa elementos consecutivos mientras la condición sea verdadera
  # Útil para encontrar "rachas" o secuencias ascendentes
  numeros = [1, 2, 3, 7, 8, 9, 10, 15, 16]
  puts "\nSecuencias consecutivas (chunk_while):"
  numeros.chunk_while { |prev, curr| curr == prev + 1 }.each do |grupo|
    if grupo.size > 1
      puts "  #{grupo.first}..#{grupo.last} (#{grupo.size} elementos)"
    else
      puts "  #{grupo.first} (aislado)"
    end
  end

  # slice_when — corta cuando la condición es verdadera (opuesto de chunk_while)
  puts "\nCortar cuando hay salto > 2 (slice_when):"
  datos = [1, 2, 3, 10, 11, 12, 50, 51]
  datos.slice_when { |prev, curr| curr - prev > 2 }.each do |grupo|
    puts "  #{grupo.inspect}"
  end

  # Caso práctico: agrupar logs por sesión (separados por líneas vacías)
  log_entries = ["GET /home", "GET /about", "", "POST /login", "GET /dashboard", "", "GET /profile"]
  puts "\nSesiones de log:"
  log_entries.chunk { |linea| linea.empty? ? :_separator : true }.each do |_, grupo|
    puts "  Sesión: #{grupo.inspect}"
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 5: zip, flat_map
# ─────────────────────────────────────────────

def demo_zip_flat_map
  puts "=== zip y flat_map ==="

  # zip — combina arrays elemento a elemento
  nombres = %w[Ana Bob Carlos]
  edades = [28, 35, 42]
  ciudades = %w[Madrid Lima Bogotá]

  combinados = nombres.zip(edades, ciudades)
  puts "zip básico: #{combinados.inspect}"
  # => [["Ana", 28, "Madrid"], ["Bob", 35, "Lima"], ["Carlos", 42, "Bogotá"]]

  # zip con bloque
  puts "zip con bloque:"
  nombres.zip(edades) { |nom, edad| puts "  #{nom} tiene #{edad} años" }

  # zip con arrays de diferente tamaño (rellena con nil)
  corto = [1, 2]
  largo = %w[a b c d]
  puts "zip diferente tamaño: #{corto.zip(largo).inspect}"
  # => [[1, "a"], [2, "b"]]  (corto limita)

  # flat_map — map + flatten(1) en un solo paso
  # Es más eficiente que .map { }.flatten
  oraciones = ["Hola mundo", "Ruby es genial", "Flat map rocks"]
  palabras = oraciones.flat_map(&:split)
  puts "\nflat_map palabras: #{palabras.inspect}"

  # flat_map para expandir relaciones 1:N
  equipos = [
    { equipo: "Alpha", miembros: %w[Ana Bob] },
    { equipo: "Beta", miembros: %w[Carlos Diana Eve] }
  ]

  todos_miembros = equipos.flat_map { |equ| equ[:miembros] }
  puts "Todos los miembros: #{todos_miembros.inspect}"

  # flat_map con expansión condicional
  numeros = [1, 2, 3, 4, 5]
  expandido = numeros.flat_map { |num| num.even? ? [num, num * 10] : [num] }
  puts "Expandir pares: #{expandido.inspect}"
  # => [1, 2, 20, 3, 4, 40, 5]
  puts
end

# ─────────────────────────────────────────────
# Sección 6: each_cons, each_slice
# ─────────────────────────────────────────────

def demo_each_cons_slice
  puts "=== each_cons y each_slice ==="

  datos = [10, 20, 30, 40, 50, 60, 70, 80]

  # each_slice — divide en grupos de N elementos
  puts "each_slice(3):"
  datos.each_slice(3) { |grupo| puts "  #{grupo.inspect}" }
  # => [10, 20, 30], [40, 50, 60], [70, 80]

  # each_cons — ventana deslizante de N elementos consecutivos
  puts "\neach_cons(3) — ventana deslizante:"
  datos.each_cons(3) { |ventana| puts "  #{ventana.inspect}" }
  # => [10,20,30], [20,30,40], [30,40,50], etc.

  # Caso práctico: media móvil (moving average)
  precios = [100, 102, 98, 105, 110, 108, 115, 120]
  puts "\nMedia móvil de 3 períodos:"
  precios.each_cons(3).with_index do |ventana, idx|
    media = ventana.sum.to_f / ventana.size
    puts "  Período #{idx + 1}-#{idx + 3}: #{ventana.inspect} → promedio: #{format("%.1f", media)}"
  end

  # Caso práctico: detectar tendencias (subida/bajada)
  puts "\nTendencias entre períodos:"
  precios.each_cons(2) do |prev, curr|
    cambio = curr - prev
    tendencia = if cambio.positive?
                  "📈 Subió"
                else
                  (cambio.negative? ? "📉 Bajó" : "➡️  Igual")
                end
    puts "  #{prev} → #{curr}: #{tendencia} (#{"+" if cambio >= 0}#{cambio})"
  end

  # each_slice para procesamiento en lotes (batch processing)
  puts "\nProcesamiento en lotes de 3:"
  items = (1..10).to_a
  items.each_slice(3).with_index(1) do |lote, num|
    puts "  Lote #{num}: procesando #{lote.inspect}"
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 7: group_by y tally
# ─────────────────────────────────────────────

def demo_group_by_tally
  puts "=== group_by y tally ==="

  palabras = %w[ruby python ruby java python ruby go java python ruby]

  # tally — contar ocurrencias (Ruby 2.7+)
  conteo = palabras.tally
  puts "tally: #{conteo.inspect}"
  # => {"ruby"=>4, "python"=>3, "java"=>2, "go"=>1}

  # tally + sort para ranking
  puts "Ranking de popularidad:"
  conteo.sort_by { |_lang, cnt| -cnt }.each_with_index do |(lang, cnt), idx|
    barra = "█" * cnt
    puts "  #{idx + 1}. #{lang.ljust(8)} #{barra} (#{cnt})"
  end

  # group_by con transformación
  numeros = (1..20).to_a
  agrupados = numeros.group_by { |num| num % 3 }
  puts "\ngroup_by (mod 3):"
  agrupados.each { |residuo, vals| puts "  resto #{residuo}: #{vals.inspect}" }

  # group_by con clasificación compleja
  personas = [
    { nombre: "Ana", edad: 17 },
    { nombre: "Bob", edad: 25 },
    { nombre: "Carlos", edad: 35 },
    { nombre: "Diana", edad: 15 },
    { nombre: "Eve", edad: 42 },
    { nombre: "Frank", edad: 28 }
  ]

  por_grupo_etario = personas.group_by do |per|
    case per[:edad]
    when 0...18  then "Menor"
    when 18...30 then "Joven"
    when 30...50 then "Adulto"
    else              "Senior"
    end
  end

  puts "\nGrupos etarios:"
  por_grupo_etario.each do |grupo, miembros|
    nombres = miembros.map { |per| per[:nombre] }.join(", ")
    puts "  #{grupo}: #{nombres}"
  end

  # tally_by (Ruby 3.1+) — tally con transformación
  if [].respond_to?(:tally_by)
    resultado = personas.tally_by { |per| per[:edad] >= 18 ? "Adulto" : "Menor" }
    puts "\ntally_by edad: #{resultado}"
  else
    # Alternativa para versiones anteriores
    resultado = personas.group_by { |per| per[:edad] >= 18 ? "Adulto" : "Menor" }
                        .transform_values(&:size)
    puts "\ntally manual por edad: #{resultado}"
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 8: filter_map — Avanzado
# ─────────────────────────────────────────────
# filter_map (Ruby 2.7+) combina select + map en un solo paso.
# Retorna solo los valores truthy del bloque (descarta nil y false).

def demo_filter_map
  puts "=== filter_map ==="

  # Básico: extraer y transformar en un paso
  datos = ["42", "hello", "7", "", "13", nil, "abc", "99"]

  # Sin filter_map (dos pasos):
  # datos.select { |d| d&.match?(/\A\d+\z/) }.map(&:to_i)

  # Con filter_map (un paso, más limpio):
  numeros = datos.filter_map do |val|
    val&.match?(/\A\d+\z/) ? val.to_i : nil
  end
  puts "Números extraídos: #{numeros.inspect}" # => [42, 7, 13, 99]

  # Parsear datos con posibles errores
  registros = [
    "user:ana:28",
    "user:bob:",          # Edad faltante
    "user:carlos:35",
    "invalid-format",     # Formato inválido
    "user:diana:22"
  ]

  usuarios = registros.filter_map do |registro|
    partes = registro.split(":")
    next nil unless partes.size == 3 && partes[0] == "user" && !partes[2].empty?

    { nombre: partes[1], edad: partes[2].to_i }
  end
  puts "Usuarios válidos: #{usuarios.inspect}"

  # filter_map con índice
  letras = %w[a b c d e f g h]
  pares_con_indice = letras.each_with_index.filter_map do |letra, idx|
    idx.even? ? "#{idx}:#{letra}" : nil
  end
  puts "Índices pares: #{pares_con_indice.inspect}"

  # Versus compact + map
  valores = [1, nil, 2, nil, 3, nil]
  # Ambos son equivalentes:
  con_compact = valores.compact.map { |val| val * 10 }
  con_filter = valores.filter_map { |val| val&.*(10) }
  puts "compact+map: #{con_compact.inspect}"
  puts "filter_map:  #{con_filter.inspect}"

  # filter_map con hash — procesar y filtrar pares clave-valor
  inventario = { laptop: 5, mouse: 0, teclado: 3, monitor: 0, cable: 15 }
  en_stock = inventario.filter_map { |prod, qty| qty.positive? ? "#{prod} (#{qty})" : nil }
  puts "En stock: #{en_stock.inspect}"
  puts
end

# ─────────────────────────────────────────────
# Sección 9: Enumerator::Yielder y generadores
# ─────────────────────────────────────────────

def demo_generadores
  puts "=== Generadores con Enumerator ==="

  # Generador infinito de números primos
  primos = Enumerator.new do |yielder|
    candidato = 2
    loop do
      es_primo = (2...candidato).none? { |div| (candidato % div).zero? }
      yielder.yield candidato if es_primo
      candidato += 1
    end
  end

  puts "Primeros 15 primos: #{primos.take(15).inspect}"

  # Generador con estado: secuencia de Collatz
  collatz = lambda do |num|
    Enumerator.new do |yielder|
      current = num
      loop do
        yielder.yield current
        break if current == 1

        current = current.even? ? current / 2 : (current * 3) + 1
      end
    end
  end

  puts "\nCollatz(27): #{collatz.call(27).to_a.first(10).inspect}... (#{collatz.call(27).count} pasos)"

  # Enumerator.produce (Ruby 2.7+) — genera valores sucesivos
  if Enumerator.respond_to?(:produce)
    # Potencias de 2
    potencias = Enumerator.produce(1) { |val| val * 2 }
    puts "\nPotencias de 2: #{potencias.take(10).inspect}"

    # Fibonacci con produce
    fib = Enumerator.produce([0, 1]) { |prev, curr| [curr, prev + curr] }
    fib_nums = fib.lazy.map(&:first).take(10).to_a
    puts "Fibonacci con produce: #{fib_nums.inspect}"
  end

  # Chaining enumerators con +
  enum1 = [1, 2, 3].each
  enum2 = [4, 5, 6].each
  combinado = enum1 + enum2
  puts "\nEnumerators encadenados: #{combinado.to_a.inspect}"
  puts
end

# ─────────────────────────────────────────────
# Sección 10: Patrones avanzados y composición
# ─────────────────────────────────────────────

def demo_patrones_avanzados
  puts "=== Patrones avanzados ==="

  # each_with_object — acumular en un objeto mutable
  frecuencias = %w[ruby python ruby java python ruby go].each_with_object(Hash.new(0)) do |lang, hash| # rubocop:disable Style/TallyMethod
    hash[lang] += 1
  end
  puts "each_with_object: #{frecuencias.inspect}"

  # reduce vs each_with_object para construir hashes
  # ⚠️ Error común con reduce: olvidar retornar el acumulador
  # ❌ Mal: [].reduce({}) { |acc, x| acc[x] = true }  # retorna true, no acc
  # ✅ Bien: [].reduce({}) { |acc, x| acc[x] = true; acc }
  # ✅ Mejor: [].each_with_object({}) { |x, acc| acc[x] = true }

  # inject/reduce con símbolo
  puts "Suma con reduce(:+): #{(1..10).reduce(:+)}"
  puts "Producto con reduce(:*): #{(1..5).reduce(:*)}"

  # min_by, max_by, minmax_by
  datos = [{ n: "a", v: 30 }, { n: "b", v: 10 }, { n: "c", v: 50 }, { n: "d", v: 20 }]
  puts "\nmax_by: #{datos.max_by { |item| item[:v] }}"
  puts "min_by: #{datos.min_by { |item| item[:v] }}"
  min, max = datos.minmax_by { |item| item[:v] }
  puts "minmax_by: min=#{min}, max=#{max}"

  # sum con transformación
  carrito = [{ item: "A", precio: 10, qty: 3 }, { item: "B", precio: 25, qty: 1 }]
  total = carrito.sum { |prod| prod[:precio] * prod[:qty] }
  puts "\nTotal carrito: $#{total}"

  # count con condición
  nums = (1..100).to_a
  puts "Pares en 1..100: #{nums.count(&:even?)}"
  puts "Múltiplos de 7: #{nums.count { |num| (num % 7).zero? }}"

  # flat_map + lazy para pipelines complejos
  documentos = [
    { titulo: "Ruby Basics", tags: %w[ruby programming] },
    { titulo: "Web Dev", tags: %w[html css ruby] },
    { titulo: "Data Science", tags: %w[python ml] }
  ]

  tags_unicos = documentos.flat_map { |doc| doc[:tags] }.uniq.sort
  puts "\nTags únicos: #{tags_unicos.inspect}"

  docs_ruby = documentos.select { |doc| doc[:tags].include?("ruby") }
                        .map { |doc| doc[:titulo] }
  puts "Docs con tag 'ruby': #{docs_ruby.inspect}"

  # each_slice para crear "páginas"
  items = (1..23).to_a
  paginas = items.each_slice(5).to_a
  puts "\nPaginación (5 por página):"
  paginas.each_with_index do |pagina, idx|
    puts "  Página #{idx + 1}: #{pagina.inspect}"
  end
  puts
end

# ─────────────────────────────────────────────
# Ejecución principal
# ─────────────────────────────────────────────

demo_enumerable_en_clase
demo_custom_each
demo_lazy_enumerators
demo_chunk_y_slicing
demo_zip_flat_map
demo_each_cons_slice
demo_group_by_tally
demo_filter_map
demo_generadores
demo_patrones_avanzados

puts "=" * 60
puts "Todos los demos de Enumerable avanzado completados."
