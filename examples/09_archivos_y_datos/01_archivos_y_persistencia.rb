# frozen_string_literal: true

# = Archivos y Persistencia de Datos
#
# Este ejemplo cubre lectura/escritura de archivos, CSV, JSON,
# fechas/horas, variables de entorno, archivos de configuración,
# escritura atómica segura y manejo de errores comunes.

require "csv"
require "json"
require "date"
require "time"
require "pathname"
require "tempfile"
require "fileutils"
require "tmpdir"

# ─────────────────────────────────────────────
# Sección 1: Lectura y escritura básica de archivos
# ─────────────────────────────────────────────
# Usamos Dir.mktmpdir para crear un directorio temporal que se limpia automáticamente.
# Esto evita dejar archivos basura en el sistema y no depende de estado global.

def demo_lectura_escritura_basica(base_dir)
  puts "=== Lectura y escritura básica de archivos ==="

  archivo = File.join(base_dir, "saludo.txt")

  # Escritura simple con File.write
  File.write(archivo, "Hola, mundo!\nSegunda línea.\nTercera línea.\n")
  puts "Archivo creado: #{archivo}"

  # Lectura completa del archivo
  contenido = File.read(archivo)
  puts "Contenido completo:\n#{contenido}"

  # Lectura línea por línea (ideal para archivos grandes)
  puts "Línea por línea:"
  File.foreach(archivo).with_index(1) do |linea, num|
    puts "  #{num}: #{linea.chomp}"
  end

  # Lectura como array de líneas
  lineas = File.readlines(archivo, chomp: true)
  puts "Como array: #{lineas.inspect}"

  # Escritura con modo append
  File.open(archivo, "a") do |file|
    file.puts "Línea agregada con append."
  end

  puts "Después de append:"
  puts File.read(archivo)
  puts
end

# ─────────────────────────────────────────────
# Sección 2: Pathname — API orientada a objetos para rutas
# ─────────────────────────────────────────────

def demo_pathname(base_dir)
  puts "=== Pathname: API orientada a objetos ==="

  ruta = Pathname.new(base_dir)
  puts "Directorio base: #{ruta}"
  puts "¿Existe?:        #{ruta.exist?}"
  puts "¿Es directorio?: #{ruta.directory?}"
  puts "¿Es absoluta?:   #{ruta.absolute?}"

  # Construir rutas de forma segura (evita problemas con separadores)
  archivo = ruta / "datos" / "config.txt"
  puts "Ruta construida:  #{archivo}"
  puts "Extensión:        #{archivo.extname}"
  puts "Nombre base:      #{archivo.basename}"
  puts "Directorio padre: #{archivo.dirname}"

  # Crear subdirectorios y archivos
  FileUtils.mkdir_p(archivo.dirname)
  archivo.write("contenido de prueba")
  puts "Tamaño del archivo: #{archivo.size} bytes"

  # Listar archivos en un directorio
  puts "Contenido del directorio base:"
  ruta.children.each { |hijo| puts "  #{hijo.basename} (#{hijo.directory? ? 'dir' : 'archivo'})" }
  puts
end

# ─────────────────────────────────────────────
# Sección 3: CSV — Lectura y escritura
# ─────────────────────────────────────────────

def demo_csv(base_dir)
  puts "=== CSV: Lectura y escritura ==="

  archivo_csv = File.join(base_dir, "productos.csv")

  # Escritura de CSV
  productos = [
    { nombre: "Laptop", precio: 1200.50, stock: 15 },
    { nombre: "Mouse", precio: 25.99, stock: 200 },
    { nombre: "Teclado", precio: 75.00, stock: 85 },
    { nombre: "Monitor 27\"", precio: 450.00, stock: 30 }
  ]

  CSV.open(archivo_csv, "w", headers: true) do |csv|
    csv << ["nombre", "precio", "stock"]
    productos.each do |prod|
      csv << [prod[:nombre], prod[:precio], prod[:stock]]
    end
  end
  puts "CSV escrito: #{archivo_csv}"

  # Lectura con headers (cada fila es un CSV::Row)
  puts "Leyendo CSV con headers:"
  CSV.foreach(archivo_csv, headers: true) do |row|
    nombre = row["nombre"]
    precio = row["precio"].to_f
    stock  = row["stock"].to_i
    puts "  #{nombre}: $#{'%.2f' % precio} (#{stock} unidades)"
  end

  # Lectura completa como tabla
  tabla = CSV.read(archivo_csv, headers: true)
  puts "Total de filas: #{tabla.size}"

  # Filtrar productos caros
  caros = tabla.select { |row| row["precio"].to_f > 100 }
  puts "Productos con precio > $100: #{caros.map { |row| row['nombre'] }.join(', ')}"

  # Generar CSV como string (útil para APIs)
  csv_string = CSV.generate do |csv|
    csv << ["id", "valor"]
    3.times { |idx| csv << [idx + 1, rand(100)] }
  end
  puts "CSV generado como string:\n#{csv_string}"
  puts
end

# ─────────────────────────────────────────────
# Sección 4: JSON — Serialización y deserialización
# ─────────────────────────────────────────────

def demo_json(base_dir)
  puts "=== JSON: Serialización y deserialización ==="

  archivo_json = File.join(base_dir, "config.json")

  # Estructura de datos Ruby → JSON
  configuracion = {
    app: "MiApp",
    version: "2.1.0",
    debug: false,
    base_de_datos: {
      host: "localhost",
      puerto: 5432,
      nombre: "mi_app_production"
    },
    features: ["auth", "cache", "logging"],
    limites: {
      max_conexiones: 100,
      timeout_segundos: 30.5
    }
  }

  # Escritura con formato legible (pretty print)
  File.write(archivo_json, JSON.pretty_generate(configuracion))
  puts "JSON escrito: #{archivo_json}"
  puts File.read(archivo_json)

  # Lectura y deserialización
  datos = JSON.parse(File.read(archivo_json))
  puts "\nDatos parseados (clase): #{datos.class}"
  puts "Host BD: #{datos.dig('base_de_datos', 'host')}"
  puts "Features: #{datos['features'].join(', ')}"

  # ⚠️ Cuidado: JSON.parse retorna strings como claves, no símbolos
  puts "Claves son strings: #{datos.keys.first.class}" # => String

  # Para obtener símbolos como claves:
  datos_sym = JSON.parse(File.read(archivo_json), symbolize_names: true)
  puts "Con symbolize_names: #{datos_sym.keys.first.class}" # => Symbol
  puts "Acceso con símbolo: #{datos_sym[:app]}"

  # Serialización de objetos personalizados
  # ⚠️ Error común: intentar serializar un objeto sin método to_json
  persona = { nombre: "Ana", nacimiento: Date.new(1990, 5, 15) }
  begin
    # Date no se serializa directamente de forma útil sin conversión
    json_persona = JSON.generate(persona.transform_values(&:to_s))
    puts "\nPersona como JSON: #{json_persona}"
  rescue TypeError => err
    puts "Error de serialización: #{err.message}"
  end

  # JSON inválido — manejo de errores
  begin
    JSON.parse("{ esto no es json válido }")
  rescue JSON::ParserError => err
    puts "\n⚠️  JSON inválido capturado: #{err.message[0..60]}..."
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 5: Fechas y horas
# ─────────────────────────────────────────────

def demo_fechas_y_horas
  puts "=== Fechas y horas ==="

  # Time — incluye fecha, hora y zona horaria (basado en el sistema)
  ahora = Time.now
  puts "Time.now:       #{ahora}"
  puts "Época Unix:     #{ahora.to_i}"
  puts "Formato ISO:    #{ahora.strftime('%Y-%m-%dT%H:%M:%S%z')}"
  puts "Formato humano: #{ahora.strftime('%d/%m/%Y %H:%M')}"

  # Date — solo fecha, sin hora ni zona
  hoy = Date.today
  puts "\nDate.today:    #{hoy}"
  puts "Año: #{hoy.year}, Mes: #{hoy.month}, Día: #{hoy.day}"
  puts "Día de la semana: #{hoy.strftime('%A')}"
  puts "¿Fin de semana?: #{hoy.saturday? || hoy.sunday?}"

  # Aritmética de fechas
  manana = hoy + 1
  hace_una_semana = hoy - 7
  puts "\nMañana:           #{manana}"
  puts "Hace una semana:  #{hace_una_semana}"

  # Diferencia entre fechas (en días)
  navidad = Date.new(hoy.year, 12, 25)
  navidad = Date.new(hoy.year + 1, 12, 25) if navidad < hoy
  dias_para_navidad = (navidad - hoy).to_i
  puts "Días para Navidad: #{dias_para_navidad}"

  # DateTime — combinación de fecha y hora (parte de la librería date)
  fecha_hora = DateTime.new(2025, 6, 15, 14, 30, 0, "+02:00")
  puts "\nDateTime:      #{fecha_hora}"
  puts "Zona horaria:  #{fecha_hora.zone}"

  # Parseo de strings a fechas
  fecha_parseada = Date.parse("2025-03-15")
  puts "Fecha parseada: #{fecha_parseada}"

  fecha_estricta = Date.strptime("15/06/2025", "%d/%m/%Y")
  puts "Fecha strptime: #{fecha_estricta}"

  # ⚠️ Error común: Date.parse con formatos ambiguos
  begin
    # "03/04/2025" — ¿es 3 de abril o 4 de marzo?
    # Date.parse puede interpretar de forma inesperada
    ambigua = Date.parse("03/04/2025")
    puts "\n⚠️  Fecha ambigua '03/04/2025' se interpretó como: #{ambigua}"
    puts "   Consejo: usa Date.strptime con formato explícito para evitar sorpresas."
  rescue Date::Error => err
    puts "Error al parsear fecha: #{err.message}"
  end

  # Rangos de fechas
  inicio = Date.new(2025, 1, 1)
  fin_mes = Date.new(2025, 1, 31)
  dias_laborables = (inicio..fin_mes).count { |dia| !dia.saturday? && !dia.sunday? }
  puts "\nDías laborables en enero 2025: #{dias_laborables}"
  puts
end

# ─────────────────────────────────────────────
# Sección 6: Variables de entorno
# ─────────────────────────────────────────────

def demo_variables_entorno
  puts "=== Variables de entorno ==="

  # Acceso directo (retorna nil si no existe)
  path = ENV["PATH"]
  puts "PATH (primeros 80 chars): #{path&.slice(0, 80)}..."

  # Acceso seguro con valor por defecto
  entorno = ENV.fetch("RUBY_ENV", "development")
  puts "RUBY_ENV: #{entorno}"

  # ⚠️ ENV.fetch sin default lanza KeyError si la variable no existe
  begin
    ENV.fetch("VARIABLE_QUE_NO_EXISTE_XYZ_123")
  rescue KeyError => err
    puts "⚠️  Variable no encontrada: #{err.message}"
  end

  # Listar variables de entorno (primeras 5)
  puts "\nPrimeras 5 variables de entorno:"
  ENV.first(5).each do |clave, valor|
    puts "  #{clave} = #{valor&.slice(0, 50)}#{valor && valor.length > 50 ? '...' : ''}"
  end

  # Patrón común: configuración basada en entorno
  config = {
    database_url: ENV.fetch("DATABASE_URL", "sqlite3:///db/development.sqlite3"),
    redis_url: ENV.fetch("REDIS_URL", "redis://localhost:6379"),
    log_level: ENV.fetch("LOG_LEVEL", "info")
  }
  puts "\nConfiguración desde ENV:"
  config.each { |clave, valor| puts "  #{clave}: #{valor}" }
  puts
end

# ─────────────────────────────────────────────
# Sección 7: Archivos de configuración (YAML-like con JSON)
# ─────────────────────────────────────────────
# Nota: YAML es común en Ruby pero requiere cuidado con Psych.safe_load.
# Aquí usamos JSON como formato de configuración seguro y portable.

def demo_archivos_configuracion(base_dir)
  puts "=== Archivos de configuración ==="

  config_file = File.join(base_dir, "app_config.json")

  # Configuración por defecto
  defaults = {
    server: { host: "0.0.0.0", port: 3000 },
    logging: { level: "info", file: "app.log" },
    cache: { enabled: true, ttl: 3600 }
  }

  # Guardar configuración
  File.write(config_file, JSON.pretty_generate(defaults))
  puts "Configuración guardada en: #{config_file}"

  # Cargar y mergear con overrides
  loaded = JSON.parse(File.read(config_file), symbolize_names: true)
  overrides = { server: { port: 8080 }, logging: { level: "debug" } }

  # Merge profundo manual (Ruby no tiene deep_merge en stdlib)
  merged = deep_merge(loaded, overrides)
  puts "Configuración mergeada:"
  puts JSON.pretty_generate(merged)
  puts
end

# Merge profundo recursivo para hashes anidados
def deep_merge(base, override)
  base.merge(override) do |_key, old_val, new_val|
    if old_val.is_a?(Hash) && new_val.is_a?(Hash)
      deep_merge(old_val, new_val)
    else
      new_val
    end
  end
end

# ─────────────────────────────────────────────
# Sección 8: Escritura atómica segura (Tempfile + rename)
# ─────────────────────────────────────────────
# Patrón: escribir en un archivo temporal y luego renombrar.
# Esto previene corrupción si el proceso se interrumpe durante la escritura.

def demo_escritura_atomica(base_dir)
  puts "=== Escritura atómica segura ==="

  archivo_destino = File.join(base_dir, "datos_importantes.json")

  datos = { transacciones: 42, total: 15_780.50, timestamp: Time.now.to_s }

  # Paso 1: Escribir en archivo temporal en el mismo directorio
  # (importante: mismo filesystem para que rename sea atómico)
  escritura_atomica(archivo_destino, JSON.pretty_generate(datos))

  puts "Archivo escrito atómicamente: #{archivo_destino}"
  puts File.read(archivo_destino)

  # Simular actualización segura
  datos[:transacciones] = 43
  datos[:total] = 16_100.25
  datos[:timestamp] = Time.now.to_s

  escritura_atomica(archivo_destino, JSON.pretty_generate(datos))
  puts "\nArchivo actualizado atómicamente:"
  puts File.read(archivo_destino)
  puts
end

def escritura_atomica(destino, contenido)
  dir = File.dirname(destino)
  # Tempfile en el mismo directorio garantiza rename atómico
  temp = Tempfile.new(["atomic_", File.extname(destino)], dir)
  begin
    temp.write(contenido)
    temp.close
    # File.rename es atómico en el mismo filesystem
    File.rename(temp.path, destino)
  rescue StandardError
    temp.close!
    raise
  end
end

# ─────────────────────────────────────────────
# Sección 9: Manejo de errores con archivos
# ─────────────────────────────────────────────

def demo_manejo_errores(base_dir)
  puts "=== Manejo de errores con archivos ==="

  # 1. Archivo que no existe
  begin
    File.read(File.join(base_dir, "no_existe.txt"))
  rescue Errno::ENOENT => err
    puts "✓ Archivo no encontrado: #{err.message}"
  end

  # 2. Directorio que no existe
  begin
    File.write("/ruta/que/no/existe/archivo.txt", "datos")
  rescue Errno::ENOENT => err
    puts "✓ Directorio no encontrado: #{err.message}"
  end

  # 3. Permisos insuficientes (simulado con ejemplo)
  puts "✓ Errno::EACCES se lanza cuando no hay permisos de lectura/escritura"

  # 4. JSON corrupto
  archivo_corrupto = File.join(base_dir, "corrupto.json")
  File.write(archivo_corrupto, '{"nombre": "test", precio: }')
  begin
    JSON.parse(File.read(archivo_corrupto))
  rescue JSON::ParserError => err
    puts "✓ JSON corrupto: #{err.message[0..60]}..."
  end

  # 5. CSV con formato inconsistente
  archivo_csv_malo = File.join(base_dir, "malo.csv")
  File.write(archivo_csv_malo, "a,b,c\n1,2\n3,4,5,6\n")
  puts "CSV con filas inconsistentes:"
  CSV.foreach(archivo_csv_malo, headers: true) do |row|
    puts "  Campos: #{row.fields.inspect} (#{row.fields.compact.size} valores)"
  end

  # 6. Patrón robusto: cargar con fallback
  resultado = cargar_json_seguro(File.join(base_dir, "no_existe.json"), { default: true })
  puts "\nCargar con fallback: #{resultado.inspect}"

  resultado = cargar_json_seguro(archivo_corrupto, { default: true })
  puts "Cargar corrupto con fallback: #{resultado.inspect}"
  puts
end

# Carga un archivo JSON de forma segura, retornando un valor por defecto si falla
def cargar_json_seguro(ruta, fallback = {})
  JSON.parse(File.read(ruta), symbolize_names: true)
rescue Errno::ENOENT
  warn "  Advertencia: archivo no encontrado '#{ruta}', usando valor por defecto"
  fallback
rescue JSON::ParserError
  warn "  Advertencia: JSON inválido en '#{ruta}', usando valor por defecto"
  fallback
end

# ─────────────────────────────────────────────
# Ejecución principal
# ─────────────────────────────────────────────

Dir.mktmpdir("ruby_archivos_demo_") do |tmp_dir|
  puts "Directorio temporal: #{tmp_dir}\n\n"

  demo_lectura_escritura_basica(tmp_dir)
  demo_pathname(tmp_dir)
  demo_csv(tmp_dir)
  demo_json(tmp_dir)
  demo_fechas_y_horas
  demo_variables_entorno
  demo_archivos_configuracion(tmp_dir)
  demo_escritura_atomica(tmp_dir)
  demo_manejo_errores(tmp_dir)

  puts "=" * 60
  puts "Todos los demos completados."
  puts "El directorio temporal se limpiará automáticamente."
end
