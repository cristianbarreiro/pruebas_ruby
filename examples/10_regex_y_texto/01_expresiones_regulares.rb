# frozen_string_literal: true

# = Expresiones Regulares
#
# Este ejemplo cubre literales regex, match/scan/gsub, capturas,
# capturas con nombre, patrones comunes (email, logs, URLs),
# consideraciones de rendimiento y backtracking catastrófico.

# ─────────────────────────────────────────────
# Sección 1: Literales regex y operadores básicos
# ─────────────────────────────────────────────

def demo_literales_y_operadores
  puts "=== Literales regex y operadores básicos ==="

  texto = "Ruby fue creado en 1995 por Yukihiro Matsumoto"

  # Operador =~ retorna la posición del primer match (o nil)
  posicion = texto =~ /\d+/
  puts "Posición del primer número: #{posicion}" # => 21
  puts "Después de =~, Regexp.last_match contiene el MatchData: #{Regexp.last_match[0]}" if Regexp.last_match # => 1995

  # Operador match retorna un MatchData (o nil)
  resultado = texto.match(/(\d{4})/)
  puts "match result: #{resultado[0]}" if resultado # => 1995
  puts "Captura 1:    #{resultado[1]}" if resultado # => 1995

  # match? retorna solo true/false (más eficiente, no crea MatchData)
  puts "¿Contiene números?: #{texto.match?(/\d+/)}" # => true
  puts "¿Contiene emoji?:   #{texto.match?(/\p{Emoji}/)}" # => false

  # Operador === (útil en case/when)
  clasificar = lambda { |txt|
    case txt
    when /\A\d+\z/        then "Solo números"
    when /\A[a-zA-Z]+\z/  then "Solo letras"
    when /\A\S+@\S+\z/    then "Parece un email"
    else                       "Mixto u otro"
    end
  }

  ["42", "hola", "user@test.com", "hola mundo"].each do |txt|
    puts "  '#{txt}' → #{clasificar.call(txt)}"
  end
  puts
end

# ─────────────────────────────────────────────
# Sección 2: scan, gsub y sub
# ─────────────────────────────────────────────

def demo_scan_gsub
  puts "=== scan, gsub y sub ==="

  texto = "Tengo 3 gatos, 2 perros y 15 peces en 1 acuario."

  # scan — encontrar TODAS las coincidencias
  numeros = texto.scan(/\d+/)
  puts "Números encontrados: #{numeros.inspect}" # => ["3", "2", "15", "1"]

  # scan con capturas — retorna arrays anidados
  pares = texto.scan(/(\d+)\s+(\w+)/)
  puts "Pares número-palabra: #{pares.inspect}"
  # => [["3", "gatos"], ["2", "perros"], ["15", "peces"], ["1", "acuario"]]

  # sub — reemplaza solo la PRIMERA coincidencia
  puts texto.sub(/\d+/, "NÚMERO")
  # => "Tengo NÚMERO gatos, 2 perros..."

  # gsub — reemplaza TODAS las coincidencias
  puts texto.gsub(/\d+/, "N")
  # => "Tengo N gatos, N perros y N peces en N acuario."

  # gsub con bloque — transformación dinámica
  resultado = texto.gsub(/\d+/) { |num| num.to_i * 10 }
  puts "Multiplicado x10: #{resultado}"

  # gsub con hash de reemplazos
  censored = "foo bar baz".gsub(/foo|bar/) { |match| { "foo" => "***", "bar" => "---" }[match] }
  puts "Con hash: #{censored}"

  # gsub con backreferences en el string de reemplazo
  puts "Juan Pérez".gsub(/(\w+)\s+(\w+)/, '\2, \1') # => "Pérez, Juan"
  puts
end

# ─────────────────────────────────────────────
# Sección 3: Capturas (grupos)
# ─────────────────────────────────────────────

def demo_capturas
  puts "=== Capturas (grupos) ==="

  # Capturas numeradas
  fecha_texto = "Fecha: 2025-06-15"
  match = fecha_texto.match(/(\d{4})-(\d{2})-(\d{2})/)
  if match
    puts "Match completo: #{match[0]}"  # => 2025-06-15
    puts "Año:  #{match[1]}"            # => 2025
    puts "Mes:  #{match[2]}"            # => 06
    puts "Día:  #{match[3]}"            # => 15
    puts "Capturas: #{match.captures}"  # => ["2025", "06", "15"]
  end

  # Capturas con nombre (?<nombre>...)
  log_line = '192.168.1.100 - - [15/Jun/2025:14:30:00 +0000] "GET /index.html HTTP/1.1" 200 1234'

  patron_log = %r{
    (?<ip>\d+\.\d+\.\d+\.\d+)     # Dirección IP
    \s+-\s+-\s+
    \[(?<fecha>[^\]]+)\]            # Fecha entre corchetes
    \s+"(?<metodo>\w+)              # Método HTTP
    \s+(?<ruta>\S+)                 # Ruta solicitada
    \s+HTTP/[\d.]+"                 # Versión HTTP
    \s+(?<codigo>\d{3})             # Código de estado
    \s+(?<bytes>\d+)                # Bytes transferidos
  }x # Flag x permite comentarios y espacios

  log_match = log_line.match(patron_log)
  if log_match
    puts "\nLog parseado con capturas nombradas:"
    puts "  IP:      #{log_match[:ip]}"
    puts "  Fecha:   #{log_match[:fecha]}"
    puts "  Método:  #{log_match[:metodo]}"
    puts "  Ruta:    #{log_match[:ruta]}"
    puts "  Código:  #{log_match[:codigo]}"
    puts "  Bytes:   #{log_match[:bytes]}"

    # named_captures retorna un Hash
    puts "  named_captures: #{log_match.named_captures}"
  end

  # Grupos no capturantes (?:...)
  # Agrupan sin crear una captura
  match_nc = "color: rojo".match(/color:\s+(?:rojo|azul|verde)/)
  puts "\nGrupo no capturante match: #{match_nc[0]}"
  puts "Capturas (vacías): #{match_nc.captures.inspect}" # => []
  puts
end

# ─────────────────────────────────────────────
# Sección 4: Patrones comunes
# ─────────────────────────────────────────────

def demo_patrones_comunes
  puts "=== Patrones comunes ==="

  # 1. Validación básica de email
  # ⚠️ La validación perfecta de email por regex es extremadamente compleja.
  # Este patrón cubre los casos más comunes, no es RFC 5322 completo.
  patron_email = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i

  emails = ["usuario@ejemplo.com", "nombre.apellido@sub.dominio.co", "invalido@", "@dominio.com", "test@test"]
  puts "Validación de emails:"
  emails.each do |email|
    valido = email.match?(patron_email) ? "✓" : "✗"
    puts "  #{valido} #{email}"
  end

  # 2. Extracción de URLs
  patron_url = %r{https?://[^\s<>"']+}i

  texto_con_urls = <<~TEXT
    Visita https://www.ruby-lang.org para más info.
    Documentación en http://docs.ejemplo.com/api/v2
    Y también https://github.com/ruby/ruby es útil.
  TEXT

  urls = texto_con_urls.scan(patron_url)
  puts "\nURLs encontradas:"
  urls.each { |url| puts "  #{url}" }

  # 3. Parseo de logs de aplicación
  logs = <<~LOGS
    [2025-06-15 14:30:00] INFO  -- : Servidor iniciado en puerto 3000
    [2025-06-15 14:30:05] WARN  -- : Conexión lenta detectada (2.5s)
    [2025-06-15 14:30:10] ERROR -- : No se pudo conectar a la base de datos
    [2025-06-15 14:30:15] INFO  -- : Reconexión exitosa
  LOGS

  patron_log_app = /\[(?<timestamp>[^\]]+)\]\s+(?<level>\w+)\s+--\s+:\s+(?<message>.+)/

  puts "\nLogs parseados:"
  logs.each_line do |linea|
    match = linea.match(patron_log_app)
    next unless match

    nivel_emoji = { "INFO" => "ℹ️", "WARN" => "⚠️", "ERROR" => "❌" }
    emoji = nivel_emoji.fetch(match[:level], "?")
    puts "  #{emoji} [#{match[:timestamp]}] #{match[:message]}"
  end

  # 4. Extracción de números de teléfono (formato variado)
  telefonos_texto = "Llama al +1-555-123-4567 o al (555) 987-6543 o 555.111.2222"
  patron_tel = /(?:\+\d{1,3}[-.]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.]?\d{4}/
  telefonos = telefonos_texto.scan(patron_tel)
  puts "\nTeléfonos encontrados: #{telefonos.inspect}"

  # 5. Limpiar y normalizar texto
  texto_sucio = "  Mucho   espacio    y\t\ttabs  aquí  "
  limpio = texto_sucio.strip.gsub(/\s+/, " ")
  puts "\nTexto limpio: '#{limpio}'"
  puts
end

# ─────────────────────────────────────────────
# Sección 5: Flags y modificadores
# ─────────────────────────────────────────────

def demo_flags
  puts "=== Flags y modificadores ==="

  texto = "Primera LÍNEA\nSegunda línea\nTERCERA línea"

  # /i — case insensitive
  puts "Case insensitive: #{texto.scan(/línea/i).inspect}" # => ["LÍNEA", "línea", "línea"]
  puts "Case sensitive:   #{texto.scan(/línea/).inspect}" # => ["línea", "línea"]

  # /m — multiline (. incluye \n)
  puts "Sin /m: #{texto.match?(/Primera.+TERCERA/)}"   # => false
  puts "Con /m: #{texto.match?(/Primera.+TERCERA/m)}"  # => true

  # /x — extended (permite espacios y comentarios)
  patron_fecha = %r{
    (?<anio>\d{4})    # Año con 4 dígitos
    [-/]             # Separador (guión o barra)
    (?<mes>\d{2})     # Mes con 2 dígitos
    [-/]             # Separador
    (?<dia>\d{2})     # Día con 2 dígitos
  }x

  match = "2025-06-15".match(patron_fecha)
  puts "Regex extendido: #{match[:anio]}/#{match[:mes]}/#{match[:dia]}" if match

  # Combinando flags
  puts "Combinando /im: #{texto.scan(/^.*línea$/im).inspect}"
  puts
end

# ─────────────────────────────────────────────
# Sección 6: Rendimiento y backtracking catastrófico
# ─────────────────────────────────────────────

def demo_rendimiento
  puts "=== Rendimiento y backtracking catastrófico ==="

  # ✅ Buena práctica: usar match? cuando solo necesitas true/false
  # match? es más rápido que =~ o match porque no crea MatchData ni actualiza $~
  texto = "Hello World 123"
  puts "match? es el más eficiente para verificaciones booleanas"
  puts "  match?: #{texto.match?(/\d+/)}"

  # ✅ Compilar regex que se usan repetidamente
  # Almacenar en constantes o variables evita recompilar en cada iteración
  patron_compilado = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  emails = Array.new(5) { |idx| "user#{idx}@example.com" }
  resultados = emails.grep(patron_compilado)
  puts "  Emails válidos con regex compilado: #{resultados.size}"

  # ⚠️ BACKTRACKING CATASTRÓFICO
  # Ocurre cuando un regex tiene cuantificadores anidados ambiguos
  # que causan que el motor explore exponencialmente muchas combinaciones.
  puts "\n⚠️  Backtracking catastrófico:"
  puts "  Patrones peligrosos (NO USAR en producción con input no confiable):"
  puts "    /(a+)+$/          — cuantificadores anidados"
  puts "    /(a|a)+$/         — alternativas redundantes"
  puts "    /(.*a){10}/       — repetición de grupo con .* interno"
  puts "    /([a-z]+)*$/      — grupo con + dentro de *"

  # Ejemplo seguro de demostración (con string corto y timeout implícito)
  # NO ejecutamos el caso catastrófico real para no bloquear el programa.
  puts "\n  Ejemplo de por qué es peligroso:"
  puts "    Regex: /(a+)+$/"
  puts "    Input: 'aaaaaaaaaaaaaaaaaaaaaaX'"
  puts "    El motor intentará 2^N combinaciones antes de fallar."
  puts "    Con N=25, son ~33 millones de intentos."

  # ✅ Cómo prevenir:
  puts "\n✅ Prevención:"
  puts "  1. Evitar cuantificadores anidados: (a+)+ → a+"
  puts "  2. Usar cuantificadores posesivos cuando sea posible: a++ (Ruby lo soporta)"
  puts "  3. Usar atomic groups: (?>a+) evita backtracking dentro del grupo"
  puts "  4. Establecer un timeout con Regexp.timeout= (Ruby 3.2+)"

  # Ruby 3.2+ soporta Regexp.timeout
  if Regexp.respond_to?(:timeout=)
    puts "\n  Regexp.timeout disponible en esta versión de Ruby."
    puts "  Uso: Regexp.timeout = 1.0  # timeout global de 1 segundo"
  else
    puts "\n  Regexp.timeout no disponible (requiere Ruby 3.2+)"
  end

  # Atomic groups y cuantificadores posesivos
  puts "\n  Ejemplo de atomic group vs normal:"
  puts "    Normal:  /(\\d+):/ — permite backtracking en \\d+"
  puts "    Atómico: /(?>\\d+):/ — NO permite backtracking, falla rápido"

  # Cuantificadores posesivos (equivalente a atomic groups)
  texto_num = "12345:"
  puts "  '#{texto_num}'.match?(/(\\d+):/) => #{texto_num.match?(/(\d+):/)}"
  puts
end

# ─────────────────────────────────────────────
# Sección 7: Métodos útiles de String con regex
# ─────────────────────────────────────────────

def demo_metodos_string
  puts "=== Métodos útiles de String con regex ==="

  texto = "Hola Mundo Cruel"

  # split con regex
  csv_line = "campo1,  campo2 , campo3  ,campo4"
  campos = csv_line.split(/\s*,\s*/)
  puts "Split con regex: #{campos.inspect}"

  # partition — divide en [antes, match, después]
  antes, separador, despues = "user@domain.com".partition(/@/)
  puts "Partition: antes='#{antes}', sep='#{separador}', después='#{despues}'"

  # start_with? / end_with? no soportan regex, pero podemos usar match?
  puts "¿Empieza con 'Hola'?: #{texto.match?(/\AHola/)}"
  puts "¿Termina con 'Cruel'?: #{texto.match?(/Cruel\z/)}"

  # slice con regex
  puts "Primer número en 'abc123def': #{"abc123def".slice(/\d+/)}"

  # count vs scan para contar ocurrencias
  frase = "la casa de la abuela en la colina"
  puts "Ocurrencias de 'la': #{frase.scan(/\bla\b/).size}"

  # tr y gsub — diferencia
  puts "tr('aeiou', '*'):    #{"hello world".tr("aeiou", "*")}" # => h*ll* w*rld
  puts "gsub(/[aeiou]/, '*'): #{"hello world".gsub(/[aeiou]/, "*")}" # => h*ll* w*rld
  puts "tr es más rápido para reemplazos carácter a carácter."

  # Freeze de regex (optimización menor, Ruby ya cachea literales)
  puts "\nNota: los literales regex en Ruby son automáticamente inmutables."
  puts "  No necesitas llamar .freeze en /patron/."
  puts
end

# ─────────────────────────────────────────────
# Sección 8: Ejemplo práctico — Parseador de datos estructurados
# ─────────────────────────────────────────────

def demo_parseador_practico
  puts "=== Ejemplo práctico: Parseador de datos ==="

  # Parsear un bloque de texto con formato clave: valor
  bloque = <<~DATOS
    Nombre: Ana García López
    Edad: 28
    Email: ana.garcia@ejemplo.com
    Teléfono: +34 612 345 678
    Ciudad: Madrid
    Salario: $45,000.00
  DATOS

  datos = {}
  bloque.each_line do |linea|
    match = linea.match(/\A\s*(?<clave>[^:]+):\s*(?<valor>.+)\s*\z/)
    next unless match

    clave = match[:clave].strip.downcase.tr(" ", "_").to_sym
    datos[clave] = match[:valor].strip
  end

  puts "Datos extraídos:"
  datos.each { |clave, valor| puts "  #{clave}: #{valor}" }

  # Limpieza y transformación de valores
  if datos[:salario]
    salario_limpio = datos[:salario].gsub(/[$,]/, "").to_f
    puts "\nSalario numérico: #{salario_limpio}"
  end

  if datos[:edad]
    edad = datos[:edad].to_i
    puts "Edad numérica: #{edad}"
  end
  puts
end

# ─────────────────────────────────────────────
# Ejecución principal
# ─────────────────────────────────────────────

demo_literales_y_operadores
demo_scan_gsub
demo_capturas
demo_patrones_comunes
demo_flags
demo_rendimiento
demo_metodos_string
demo_parseador_practico

puts "=" * 60
puts "Todos los demos de expresiones regulares completados."
