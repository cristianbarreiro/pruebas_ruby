# frozen_string_literal: true

# = Gemas y Bundler
#
# Guía completa sobre el ecosistema de paquetes de Ruby: RubyGems y Bundler.
# Este archivo es principalmente una guía de texto con ejemplos mínimos
# ejecutables donde es posible.
#
# Ejecutar: ruby 03_gemas_y_bundler.rb
# (Imprime la guía en consola con ejemplos interactivos básicos)

puts "=" * 70
puts " GEMAS Y BUNDLER - GESTIÓN DE DEPENDENCIAS EN RUBY"
puts "=" * 70

# ──────────────────────────────────────────────────────────────────────────────
# 1. ¿Qué es una Gema?
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 1. ¿Qué es una Gema? ──"

puts <<~TEXTO
  Una gema es un paquete de código Ruby empaquetado y distribuido a través
  de RubyGems.org (el repositorio público de gemas). Cada gema contiene:

    • Código fuente Ruby (lib/)
    • Un archivo .gemspec con metadatos (nombre, versión, dependencias)
    • Documentación (README, CHANGELOG)
    • Tests (spec/ o test/)
    • Opcionalmente: extensiones nativas en C

  Ejemplos de gemas populares:
    rails       → Framework web completo
    sinatra     → Framework web minimalista
    rspec       → Framework de testing
    rubocop     → Linter y formateador de código
    puma        → Servidor web
    devise      → Autenticación para Rails
    sidekiq     → Procesamiento de jobs en background
    nokogiri    → Parser de HTML/XML
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 2. Comandos básicos de gem (RubyGems CLI)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 2. Comandos básicos de gem ──"

puts <<~TEXTO
  # Instalar una gema
  gem install nombre_gema
  gem install rails -v 7.1.0          # Versión específica
  gem install nokogiri --no-document   # Sin documentación local (más rápido)

  # Listar gemas instaladas
  gem list                    # Todas las gemas
  gem list rails              # Buscar por nombre
  gem list --local            # Solo locales (sin consultar servidor)

  # Información de una gema
  gem info rails              # Detalles de la gema instalada
  gem specification rails     # Especificación completa

  # Buscar gemas en RubyGems.org
  gem search nombre           # Buscar remotamente

  # Desinstalar
  gem uninstall nombre_gema
  gem uninstall rails -v 7.0.0  # Versión específica

  # Actualizar
  gem update                  # Todas las gemas
  gem update rails            # Una gema específica

  # Limpiar versiones antiguas
  gem cleanup                 # Elimina versiones antiguas de todas las gemas

  # Ver rutas de instalación
  gem environment             # Información del entorno
  gem which rake              # Ruta del archivo principal de una gema
TEXTO

# Ejemplo ejecutable: información del entorno actual
puts "  Información del entorno actual:"
puts "    GEM_HOME: #{Gem.dir}"
puts "    GEM_PATH: #{Gem.path.join(', ')}"
puts "    Ruby version: #{RUBY_VERSION}"
puts "    RubyGems version: #{Gem::VERSION}"
puts "    Plataforma: #{Gem::Platform.local}"

# ──────────────────────────────────────────────────────────────────────────────
# 3. Versionado Semántico (SemVer)
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 3. Versionado Semántico (SemVer) ──"

puts <<~TEXTO
  Las gemas siguen Versionado Semántico (SemVer): MAJOR.MINOR.PATCH

  Ejemplo: 3.2.1
    MAJOR = 3 → Cambios incompatibles con versiones anteriores (breaking changes)
    MINOR = 2 → Nueva funcionalidad compatible con versiones anteriores
    PATCH = 1 → Correcciones de bugs compatibles

  Operadores de versión en Gemfile:
  ┌──────────────────┬──────────────────────────────────────────────┐
  │ Operador         │ Significado                                  │
  ├──────────────────┼──────────────────────────────────────────────┤
  │ gem "rails"      │ Cualquier versión (⚠️  peligroso)            │
  │ "= 7.1.0"        │ Exactamente 7.1.0                            │
  │ ">= 7.0"         │ 7.0 o superior (sin límite superior ⚠️)      │
  │ "~> 7.1"         │ >= 7.1.0 y < 8.0 (pessimistic/twiddle-wakka)│
  │ "~> 7.1.0"       │ >= 7.1.0 y < 7.2.0                          │
  │ ">= 7.0", "< 8"  │ Rango explícito                              │
  └──────────────────┴──────────────────────────────────────────────┘

  ✅ Recomendación: Usar "~>" (operador pesimista) para la mayoría de gemas.
     Permite actualizaciones de patches/minor pero previene breaking changes.
TEXTO

# Ejemplo ejecutable: Gem::Version y comparación
version_a = Gem::Version.new("3.2.1")
version_b = Gem::Version.new("3.10.0")

puts "  Comparación de versiones:"
puts "    3.2.1 < 3.10.0: #{version_a < version_b}"
puts "    (SemVer compara numéricamente, no como strings)"
puts '    "3.2.1" < "3.10.0" como string: #{"3.2.1" < "3.10.0"} (¡incorrecto!)'

# Verificar si una versión satisface un requisito
requisito = Gem::Requirement.new("~> 3.2")
puts "    ~> 3.2 satisfecho por 3.2.1: #{requisito.satisfied_by?(Gem::Version.new("3.2.1"))}"
puts "    ~> 3.2 satisfecho por 3.9.0: #{requisito.satisfied_by?(Gem::Version.new("3.9.0"))}"
puts "    ~> 3.2 satisfecho por 4.0.0: #{requisito.satisfied_by?(Gem::Version.new("4.0.0"))}"

# ──────────────────────────────────────────────────────────────────────────────
# 4. Bundler y Gemfile
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 4. Bundler y Gemfile ──"

puts <<~TEXTO
  Bundler es el gestor de dependencias estándar de Ruby. Asegura que
  todas las gemas necesarias (y sus dependencias transitivas) estén
  instaladas en versiones compatibles.

  Workflow básico:
    1. Crear un Gemfile en la raíz del proyecto
    2. Ejecutar `bundle install` para instalar dependencias
    3. Hacer commit del Gemfile.lock en control de versiones
    4. Ejecutar scripts con `bundle exec` para usar las gemas correctas

  Ejemplo de Gemfile:
  ──────────────────────────────────────────────
  # frozen_string_literal: true

  source "https://rubygems.org"

  # Framework principal
  gem "rails", "~> 7.1"

  # Base de datos
  gem "pg", "~> 1.5"           # PostgreSQL
  gem "redis", "~> 5.0"        # Cache/sessions

  # Servidor web
  gem "puma", "~> 6.0"

  # Assets y frontend
  gem "importmap-rails"
  gem "turbo-rails"

  # Solo para desarrollo y testing
  group :development, :test do
    gem "rspec-rails", "~> 6.0"
    gem "rubocop", "~> 1.60", require: false
    gem "debug"
  end

  # Solo para desarrollo
  group :development do
    gem "web-console"
    gem "listen", "~> 3.8"
  end

  # Solo para testing
  group :test do
    gem "capybara"
    gem "selenium-webdriver"
    gem "factory_bot_rails"
  end

  # Solo para producción
  group :production do
    gem "newrelic_rpm"
  end

  # Gemas específicas por plataforma
  gem "tzinfo-data", platforms: %i[windows jruby]
  ──────────────────────────────────────────────
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 5. Comandos de Bundler
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 5. Comandos de Bundler ──"

puts <<~TEXTO
  # Inicializar un proyecto con Gemfile
  bundle init                     # Crea un Gemfile básico

  # Instalar dependencias
  bundle install                  # Instala todo el Gemfile
  bundle install --without production  # Excluir grupo
  bundle install --path vendor/bundle  # Instalar localmente (deprecated, usar config)

  # Configuración (reemplaza flags de install)
  bundle config set --local path vendor/bundle
  bundle config set --local without production

  # Actualizar gemas
  bundle update                   # Actualiza TODAS las gemas
  bundle update rails             # Actualiza solo rails y sus dependencias
  bundle update --conservative    # Actualización mínima

  # Ejecutar con Bundler
  bundle exec ruby script.rb      # Ejecutar con las gemas del bundle
  bundle exec rails server        # Ejecutar comando con el entorno correcto
  bundle exec rspec               # Ejecutar tests

  # Información
  bundle list                     # Listar gemas instaladas
  bundle show rails               # Ruta de instalación de una gema
  bundle info rails               # Información detallada
  bundle outdated                 # Gemas con actualizaciones disponibles

  # Verificación
  bundle check                    # Verificar que todas las dependencias están instaladas
  bundle doctor                   # Diagnosticar problemas

  # Agregar/eliminar gemas
  bundle add rspec                # Agrega al Gemfile e instala
  bundle remove rspec             # Elimina del Gemfile

  ⚠️  IMPORTANTE: Siempre hacer commit de Gemfile.lock en aplicaciones.
     Para gemas/librerías, NO incluir Gemfile.lock (va en .gitignore).
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 6. Gemfile.lock - El archivo de bloqueo
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 6. Gemfile.lock ──"

puts <<~TEXTO
  El Gemfile.lock registra las versiones EXACTAS instaladas, incluyendo
  todas las dependencias transitivas. Esto garantiza reproducibilidad:
  todos los desarrolladores y servidores usan exactamente las mismas versiones.

  Ejemplo parcial de Gemfile.lock:
  ──────────────────────────────────────────────
  GEM
    remote: https://rubygems.org/
    specs:
      actioncable (7.1.3)
        actionpack (= 7.1.3)
        activesupport (= 7.1.3)
        nio4r (~> 2.0)
        websocket-driver (>= 0.6.1)
      rails (7.1.3)
        actioncable (= 7.1.3)
        actionmailbox (= 7.1.3)
        ...

  PLATFORMS
    ruby
    x86_64-linux

  DEPENDENCIES
    rails (~> 7.1)
    pg (~> 1.5)

  BUNDLED WITH
    2.5.3
  ──────────────────────────────────────────────

  Reglas:
    ✅ Aplicaciones (Rails app, etc.): Commit Gemfile.lock
    ❌ Librerías/Gemas: NO commit Gemfile.lock (añadir a .gitignore)
       (Las librerías deben ser flexibles con versiones de dependencias)
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 7. Estructura de una Gema
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 7. Estructura de una Gema ──"

puts <<~TEXTO
  Para crear una gema nueva:
    bundle gem mi_gema              # Genera la estructura completa
    bundle gem mi_gema --test=rspec # Con RSpec como framework de test

  Estructura generada:
  ──────────────────────────────────────────────
  mi_gema/
  ├── Gemfile                    # Dependencias de desarrollo
  ├── Rakefile                   # Tareas (test, build, release)
  ├── README.md                  # Documentación
  ├── CHANGELOG.md               # Historial de cambios
  ├── LICENSE.txt                # Licencia
  ├── mi_gema.gemspec            # Especificación de la gema
  ├── lib/
  │   ├── mi_gema.rb             # Punto de entrada (require "mi_gema")
  │   └── mi_gema/
  │       ├── version.rb         # Constante de versión
  │       └── ...                # Módulos y clases
  ├── spec/                      # Tests (si usas RSpec)
  │   ├── spec_helper.rb
  │   └── mi_gema_spec.rb
  ├── sig/                       # Type signatures (RBS)
  │   └── mi_gema.rbs
  └── bin/
      ├── console                # IRB con la gema cargada
      └── setup                  # Script de instalación
  ──────────────────────────────────────────────
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 8. El archivo .gemspec
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 8. El archivo .gemspec ──"

puts <<~TEXTO
  El .gemspec define los metadatos y dependencias de la gema:
  ──────────────────────────────────────────────
  # frozen_string_literal: true

  require_relative "lib/mi_gema/version"

  Gem::Specification.new do |spec|
    spec.name          = "mi_gema"
    spec.version       = MiGema::VERSION
    spec.authors       = ["Tu Nombre"]
    spec.email         = ["tu@email.com"]

    spec.summary       = "Resumen breve de la gema"
    spec.description   = "Descripción detallada de lo que hace la gema"
    spec.homepage      = "https://github.com/usuario/mi_gema"
    spec.license       = "MIT"

    # Versión mínima de Ruby requerida
    spec.required_ruby_version = ">= 3.1.0"

    # Metadatos adicionales
    spec.metadata["homepage_uri"]    = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"]   = "\#{spec.homepage}/blob/main/CHANGELOG.md"

    # Archivos incluidos en la gema
    spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
    spec.require_paths = ["lib"]

    # Dependencias de runtime (las necesita el usuario de la gema)
    spec.add_dependency "activesupport", "~> 7.0"
    spec.add_dependency "dry-struct", "~> 1.6"

    # Dependencias de desarrollo (solo para contribuidores)
    # Nota: En Ruby moderno, preferir ponerlas en el Gemfile
    # spec.add_development_dependency "rspec", "~> 3.12"
  end
  ──────────────────────────────────────────────
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 9. Publicar y construir una gema
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 9. Publicar y construir una gema ──"

puts <<~TEXTO
  # Construir la gema (crea un archivo .gem)
  gem build mi_gema.gemspec
  # → mi_gema-0.1.0.gem

  # Instalar localmente para probar
  gem install mi_gema-0.1.0.gem

  # Publicar en RubyGems.org
  gem push mi_gema-0.1.0.gem
  # (Requiere cuenta en RubyGems.org y API key)

  # O usar Rake tasks (incluidas por bundle gem):
  rake build       # Construir
  rake install     # Instalar localmente
  rake release     # Tag en git + push a RubyGems

  # Para gemas privadas, considerar:
  #   • Gemfury (gemfury.com)
  #   • GitHub Packages
  #   • Servidor Geminabox propio
  #   • Apuntar directamente al repo git en el Gemfile:
  #     gem "mi_gema", git: "https://github.com/org/mi_gema.git"
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 10. Gemfile avanzado: fuentes y opciones
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 10. Gemfile avanzado ──"

puts <<~TEXTO
  # frozen_string_literal: true

  source "https://rubygems.org"

  # Ruby version (Bundler verificará la versión)
  ruby "~> 3.3.0"

  # Gema desde Git
  gem "mi_gema", git: "https://github.com/user/mi_gema.git"
  gem "mi_gema", git: "https://github.com/user/mi_gema.git", branch: "develop"
  gem "mi_gema", git: "https://github.com/user/mi_gema.git", tag: "v1.0.0"

  # Gema desde path local (útil durante desarrollo)
  gem "mi_gema", path: "../mi_gema"

  # require: false → No cargar automáticamente (cargar manualmente cuando se necesite)
  gem "rubocop", require: false
  gem "debug", require: false

  # Grupos con bloque
  group :development do
    gem "solargraph"      # LSP para Ruby
    gem "ruby-lsp"        # Language Server Protocol
  end

  # Plataformas específicas
  platforms :ruby do
    gem "sqlite3"         # Solo en MRI Ruby
  end

  platforms :jruby do
    gem "activerecord-jdbcsqlite3-adapter"
  end

  # Gema desde un servidor privado
  source "https://gems.empresa.com" do
    gem "gema_interna"
  end
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 11. Ejemplo ejecutable: Usar Gem::Specification programáticamente
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 11. Introspección de gemas instaladas (ejemplo ejecutable) ──"

# Listar algunas gemas instaladas
gemas = Gem::Specification.to_a.sort_by(&:name)
puts "  Total de gemas instaladas: #{gemas.size}"
puts ""
puts "  Primeras 10 gemas:"
gemas.first(10).each do |gema|
  puts "    #{gema.name.ljust(25)} #{gema.version.to_s.ljust(12)} #{gema.summary.to_s[0..45]}"
end

# Buscar una gema específica
begin
  bundler_spec = Gem::Specification.find_by_name("bundler")
  puts ""
  puts "  Detalle de Bundler:"
  puts "    Versión:  #{bundler_spec.version}"
  puts "    Ruta:     #{bundler_spec.gem_dir}"
  puts "    Autores:  #{bundler_spec.authors.join(', ')}"
rescue Gem::MissingSpecError
  puts "  Bundler no encontrado en las gemas instaladas"
end

# ──────────────────────────────────────────────────────────────────────────────
# 12. require vs require_relative vs autoload
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 12. require vs require_relative vs autoload ──"

puts <<~TEXTO
  require "json"
    → Busca en $LOAD_PATH (gemas instaladas, lib/ del proyecto)
    → Evita cargar el mismo archivo dos veces
    → Usado para gemas y librerías estándar

  require_relative "mi_modulo"
    → Busca relativo al archivo actual
    → Usado para archivos dentro del mismo proyecto
    → No depende de $LOAD_PATH

  autoload :MiClase, "mi_gema/mi_clase"
    → Carga el archivo solo cuando se accede a la constante MiClase
    → Lazy loading (mejora tiempo de arranque)
    → ⚠️  No es thread-safe en versiones antiguas de Ruby

  Bundler.require
    → Automáticamente hace require de todas las gemas del Gemfile
    → Excepto las marcadas con require: false
    → Usado típicamente en Rails (config/application.rb)
TEXTO

# Ejemplo: $LOAD_PATH
puts "  $LOAD_PATH contiene #{$LOAD_PATH.size} rutas"
puts "  Primeras 3:"
$LOAD_PATH.first(3).each { |path| puts "    #{path}" }

# ──────────────────────────────────────────────────────────────────────────────
# 13. Buenas prácticas de gestión de dependencias
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 13. Buenas prácticas ──"

puts <<~TEXTO
  ✅ Siempre usar Bundler en proyectos Ruby (no instalar gemas globalmente)
  ✅ Hacer commit de Gemfile.lock en aplicaciones
  ✅ Usar operador pesimista "~>" para versiones
  ✅ Agrupar gemas por entorno (development, test, production)
  ✅ Usar "require: false" para gemas que no necesitan cargarse siempre
  ✅ Ejecutar "bundle update" regularmente para parches de seguridad
  ✅ Revisar "bundle outdated" periódicamente
  ✅ Usar "bundle audit" para detectar vulnerabilidades conocidas

  ❌ No usar "gem install" para dependencias de proyecto
  ❌ No omitir Gemfile.lock del control de versiones (en apps)
  ❌ No usar ">=" sin límite superior (puede romper con major version bump)
  ❌ No agregar gemas innecesarias (cada dependencia es un riesgo)
  ❌ No ignorar advertencias de deprecación de gemas

  🔒 Seguridad:
     gem install bundler-audit    # Instalar auditor
     bundle audit                 # Verificar vulnerabilidades
     bundle audit --update        # Actualizar base de datos de CVEs
TEXTO

# ──────────────────────────────────────────────────────────────────────────────
# 14. Resumen rápido de workflow
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 14. Resumen de workflow ──"

puts <<~TEXTO
  ┌─────────────────────────────────────────────────────────────────┐
  │                    WORKFLOW CON BUNDLER                         │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  1. Nuevo proyecto:                                             │
  │     $ mkdir mi_proyecto && cd mi_proyecto                       │
  │     $ bundle init            # Crea Gemfile                     │
  │                                                                 │
  │  2. Agregar dependencias al Gemfile                             │
  │                                                                 │
  │  3. Instalar:                                                   │
  │     $ bundle install         # Instala + genera Gemfile.lock    │
  │                                                                 │
  │  4. Ejecutar:                                                   │
  │     $ bundle exec ruby app.rb  # Con las gemas del bundle      │
  │                                                                 │
  │  5. Actualizar:                                                 │
  │     $ bundle update nombre_gema  # Actualiza una gema           │
  │     $ bundle update              # Actualiza todas              │
  │                                                                 │
  │  6. Auditar:                                                    │
  │     $ bundle audit           # Verificar vulnerabilidades       │
  │                                                                 │
  │  7. Deploy:                                                     │
  │     $ bundle install --deployment  # Modo producción            │
  │                                                                 │
  │  Nueva gema:                                                    │
  │     $ bundle gem mi_gema     # Genera estructura completa       │
  │     $ rake build             # Construir                        │
  │     $ rake release           # Publicar en RubyGems.org         │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
TEXTO

puts "✅ Archivo 03_gemas_y_bundler.rb ejecutado correctamente"
