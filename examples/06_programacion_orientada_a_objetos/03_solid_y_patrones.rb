# frozen_string_literal: true

# = SOLID y Patrones de Diseño
#
# Este archivo cubre los principios SOLID y patrones de diseño aplicados con criterio:
# - S: Single Responsibility (Responsabilidad Única)
# - O: Open/Closed (Abierto/Cerrado)
# - L: Liskov Substitution (Sustitución de Liskov)
# - I: Interface Segregation (Segregación de Interfaces)
# - D: Dependency Inversion (Inversión de Dependencias)
# - Patrón Strategy
# - Patrón Factory
# - Patrón Repository
# - Cuándo los patrones APORTAN valor vs cuándo agregan complejidad innecesaria

puts "=" * 80
puts "SOLID Y PATRONES DE DISEÑO (CON CRITERIO, NO DOGMA)"
puts "=" * 80

# ─────────────────────────────────────────────────────────────────────
# 1. S — Single Responsibility Principle (SRP)
#    "Una clase debe tener una sola razón para cambiar"
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 1. SRP: Responsabilidad Única ---"

# ⚠️ ANTES: Una clase que hace todo (God Object)
class BadOrderProcessor
  def process(items, email)
    # Calcula total, aplica descuento, envía email, guarda en BD...
    # Si cambias el cálculo de precios, tocas esta clase.
    # Si cambias el envío de emails, tocas esta clase.
    # Si cambias la persistencia, tocas esta clase.
    total = items.sum { |item| item[:price] * item[:quantity] }
    total *= 0.9 if total > 100
    puts "  [BAD] Procesando orden: $#{"%.2f" % total}, email a #{email}"
  end
end

BadOrderProcessor.new.process([{ price: 50, quantity: 3 }], "user@mail.com")

# ✅ DESPUÉS: Cada clase tiene una responsabilidad clara
class PriceCalculator
  def calculate(items)
    items.sum { |item| item[:price] * item[:quantity] }
  end
end

class DiscountPolicy
  THRESHOLD = 100

  def apply(total)
    total > THRESHOLD ? total * 0.9 : total
  end
end

class OrderNotifier
  def notify(email, total)
    puts "  [GOOD] Email a #{email}: Tu orden por $#{"%.2f" % total} fue procesada"
  end
end

class OrderProcessor
  def initialize(
    calculator: PriceCalculator.new,
    discount: DiscountPolicy.new,
    notifier: OrderNotifier.new
  )
    @calculator = calculator
    @discount = discount
    @notifier = notifier
  end

  def process(items, email)
    total = @calculator.calculate(items)
    total = @discount.apply(total)
    @notifier.notify(email, total)
    total
  end
end

processor = OrderProcessor.new
processor.process([{ price: 50, quantity: 3 }], "user@mail.com")

puts "\n  💡 SRP no significa 'una clase por método'. Significa que cada clase"
puts "     tiene una sola razón para cambiar. Usa criterio, no dogma."

# ─────────────────────────────────────────────────────────────────────
# 2. O — Open/Closed Principle (OCP)
#    "Abierto para extensión, cerrado para modificación"
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 2. OCP: Abierto/Cerrado ---"

# ⚠️ ANTES: Para agregar un formato, hay que modificar la clase
class BadExporter
  def export(data, format)
    case format
    when :json then puts "  [BAD] JSON: #{data}"
    when :csv  then puts "  [BAD] CSV: #{data.join(",")}"
    # Para agregar XML, hay que modificar este método ⚠️
    end
  end
end

# ✅ DESPUÉS: Cada formato es una clase independiente (Strategy pattern)
class JsonExporter
  def export(data)
    "{ data: #{data.inspect} }"
  end
end

class CsvExporter
  def export(data)
    data.join(",")
  end
end

class XmlExporter
  def export(data)
    data.map { |item| "<item>#{item}</item>" }.join
  end
end

# Para agregar un nuevo formato, creamos una nueva clase.
# No modificamos código existente.
class DataExporter
  def initialize(formatter)
    @formatter = formatter  # Duck typing: solo necesita #export
  end

  def export(data)
    @formatter.export(data)
  end
end

data = [1, 2, 3]
puts "  JSON: #{DataExporter.new(JsonExporter.new).export(data)}"
puts "  CSV:  #{DataExporter.new(CsvExporter.new).export(data)}"
puts "  XML:  #{DataExporter.new(XmlExporter.new).export(data)}"

# ─────────────────────────────────────────────────────────────────────
# 3. L — Liskov Substitution Principle (LSP)
#    "Las subclases deben poder sustituir a sus clases padre"
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 3. LSP: Sustitución de Liskov ---"

class Bird
  def move
    "Moviéndose"
  end
end

class Sparrow < Bird
  def move
    "Volando por el cielo ✈️"
  end
end

class Penguin < Bird
  def move
    "Caminando sobre el hielo 🐧"  # ✅ Cumple LSP: se puede sustituir sin romper nada
  end
end

# ✅ Todas las aves pueden moverse — el código cliente funciona con cualquiera
birds = [Sparrow.new, Penguin.new]
birds.each { |bird| puts "  #{bird.class}: #{bird.move}" }

puts "\n  💡 LSP en Ruby se resuelve naturalmente con duck typing."
puts "     Si un objeto responde al mismo mensaje, es sustituible."

# ─────────────────────────────────────────────────────────────────────
# 4. I — Interface Segregation Principle (ISP)
#    "No obligues a implementar métodos que no se usan"
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 4. ISP: Segregación de Interfaces ---"

# En Ruby no hay interfaces formales, pero el principio aplica con módulos.
# En vez de un módulo gigante, usamos módulos pequeños y enfocados.

module Printable
  def print_document
    puts "  🖨️ Imprimiendo: #{document_content}"
  end

  private

  def document_content
    raise NotImplementedError, "#{self.class} debe implementar #document_content"
  end
end

module Scannable
  def scan_document
    puts "  📷 Escaneando documento..."
  end
end

module Faxable
  def send_fax(number)
    puts "  📠 Enviando fax a #{number}"
  end
end

# Una impresora simple solo imprime
class BasicPrinter
  include Printable

  private

  def document_content
    "Documento básico"
  end
end

# Una impresora multifunción hace todo
class MultiFunctionPrinter
  include Printable
  include Scannable
  include Faxable

  private

  def document_content
    "Documento multifunción"
  end
end

basic = BasicPrinter.new
basic.print_document
# basic.scan_document  # ⛔ NoMethodError — correcto, no debería escanear

multi = MultiFunctionPrinter.new
multi.print_document
multi.scan_document
multi.send_fax("+34-91-1234567")

# ─────────────────────────────────────────────────────────────────────
# 5. D — Dependency Inversion Principle (DIP)
#    "Depende de abstracciones, no de implementaciones concretas"
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 5. DIP: Inversión de Dependencias ---"

# En Ruby, DIP se logra con inyección de dependencias + duck typing.
# No necesitamos interfaces abstractas como en Java.

# ⚠️ ANTES: acoplado a una implementación concreta
class BadLogger
  def log(msg)
    File.write("app.log", "#{msg}\n", mode: "a")  # Siempre escribe a archivo
  end
end

# ✅ DESPUÉS: inyectamos el destino del log
class ConsoleOutput
  def write(msg)
    puts "  [LOG] #{msg}"
  end
end

class NullOutput
  def write(_msg)
    # No hace nada — útil para tests
  end
end

class AppLogger
  def initialize(output: ConsoleOutput.new)
    @output = output  # Dependencia inyectada (duck typing: solo necesita #write)
  end

  def info(msg)
    @output.write("[INFO] #{msg}")
  end

  def error(msg)
    @output.write("[ERROR] #{msg}")
  end
end

logger = AppLogger.new
logger.info("Aplicación iniciada")
logger.error("Algo salió mal")

silent_logger = AppLogger.new(output: NullOutput.new)
silent_logger.info("Esto no se muestra")  # Silencioso — perfecto para tests

# ─────────────────────────────────────────────────────────────────────
# 6. Patrón Strategy
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 6. Patrón Strategy ---"

# El patrón Strategy encapsula algoritmos intercambiables.
# En Ruby, los bloques/lambdas son la forma más natural de implementarlo.

class Sorter
  # Strategy con clases (tradicional)
  def initialize(strategy)
    @strategy = strategy
  end

  def sort(collection)
    @strategy.sort(collection)
  end
end

class AlphabeticalSort
  def sort(collection)
    collection.sort
  end
end

class ReverseLengthSort
  def sort(collection)
    collection.sort_by { |item| -item.length }
  end
end

words = %w[ruby python go javascript elixir]

puts "  Alfabético: #{Sorter.new(AlphabeticalSort.new).sort(words).inspect}"
puts "  Por largo (desc): #{Sorter.new(ReverseLengthSort.new).sort(words).inspect}"

# ✅ Strategy con bloques — más idiomático en Ruby
puts "\n  Strategy con bloques (más Ruby):"
puts "  #{words.sort_by { |word| word.length }.inspect}"
puts "  #{words.sort_by { |word| word.reverse }.inspect}"

puts "\n  💡 No siempre necesitas una clase Strategy."
puts "     En Ruby, un bloque o lambda suele ser suficiente."

# ─────────────────────────────────────────────────────────────────────
# 7. Patrón Factory
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 7. Patrón Factory ---"

# Factory centraliza la creación de objetos complejos.
# Útil cuando la lógica de creación depende de condiciones.

class DatabaseConnection
  attr_reader :adapter, :host

  def initialize(adapter, host)
    @adapter = adapter
    @host = host
  end

  def to_s
    "#{@adapter}://#{@host}"
  end
end

class ConnectionFactory
  CONFIGS = {
    development: { adapter: "sqlite", host: "localhost" },
    test: { adapter: "sqlite", host: ":memory:" },
    production: { adapter: "postgresql", host: "db.example.com" }
  }.freeze

  def self.create(environment)
    config = CONFIGS.fetch(environment) do
      raise ArgumentError, "Entorno desconocido: #{environment}. Válidos: #{CONFIGS.keys.join(", ")}"
    end

    DatabaseConnection.new(config[:adapter], config[:host])
  end
end

%i[development test production].each do |env|
  conn = ConnectionFactory.create(env)
  puts "  #{env}: #{conn}"
end

begin
  ConnectionFactory.create(:staging)
rescue ArgumentError => err
  puts "  Error esperado: #{err.message}"
end

puts "\n  💡 Factory es útil cuando la creación es compleja o condicional."
puts "     Para objetos simples, .new es suficiente."

# ─────────────────────────────────────────────────────────────────────
# 8. Patrón Repository
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 8. Patrón Repository ---"

# Repository abstrae el acceso a datos.
# El código de negocio no sabe si los datos vienen de memoria, archivo o BD.

User = Data.define(:user_id, :name, :email)

class InMemoryUserRepository
  def initialize
    @users = {}
    @next_id = 1
  end

  def save(name, email)
    user = User.new(user_id: @next_id, name: name, email: email)
    @users[@next_id] = user
    @next_id += 1
    user
  end

  def find_by_id(user_id)
    @users.fetch(user_id) { raise "Usuario #{user_id} no encontrado" }
  end

  def find_by_email(email)
    @users.values.find { |usr| usr.email == email }
  end

  def all
    @users.values
  end

  def count
    @users.size
  end
end

# El servicio de negocio depende de la ABSTRACCIÓN del repositorio,
# no de una implementación concreta (DIP en acción).
class UserService
  def initialize(repository)
    @repo = repository
  end

  def register(name, email)
    existing = @repo.find_by_email(email)
    raise "El email #{email} ya está registrado" if existing

    user = @repo.save(name, email)
    puts "  ✅ Usuario registrado: #{user.name} (#{user.email})"
    user
  end

  def find(user_id)
    @repo.find_by_id(user_id)
  end

  def list_all
    @repo.all
  end
end

repo = InMemoryUserRepository.new
service = UserService.new(repo)

service.register("Ana García", "ana@mail.com")
service.register("Luis Pérez", "luis@mail.com")

puts "  Total usuarios: #{repo.count}"
puts "  Buscar por ID 1: #{service.find(1)}"

begin
  service.register("Otro", "ana@mail.com")  # Email duplicado
rescue RuntimeError => err
  puts "  Error esperado: #{err.message}"
end

# ─────────────────────────────────────────────────────────────────────
# 9. ⚠️ Cuándo los patrones agregan complejidad innecesaria
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 9. Criterio vs Dogma ---"

puts <<~CRITERIA
  ┌─────────────────────────────────────────────────────────────────┐
  │ ¿CUÁNDO USAR PATRONES?                                        │
  │                                                                │
  │ ✅ USA un patrón cuando:                                       │
  │   • Resuelve un problema REAL que ya tienes                    │
  │   • Simplifica el código y lo hace más legible                 │
  │   • Facilita el testing                                        │
  │   • El equipo lo entiende                                      │
  │                                                                │
  │ ⚠️ NO uses un patrón cuando:                                   │
  │   • Lo aplicas "por si acaso" necesitas flexibilidad           │
  │   • Agrega capas de indirección sin beneficio claro            │
  │   • Un método simple resuelve el problema                      │
  │   • Solo tienes una implementación (YAGNI)                     │
  │                                                                │
  │ 🔑 REGLA DE ORO:                                               │
  │   "No necesitas un AbstractFactoryStrategyBuilder              │
  │    cuando un Hash y un bloque resuelven el problema."          │
  │                                                                │
  │ Ejemplo — Strategy con bloque vs clase:                        │
  │   # ✅ Suficiente en la mayoría de casos:                      │
  │   items.sort_by { |i| i.price }                                │
  │                                                                │
  │   # Necesario solo cuando la lógica es compleja y reutilizable │
  │   Sorter.new(ComplexSortStrategy.new).sort(items)              │
  └─────────────────────────────────────────────────────────────────┘
CRITERIA

# ─────────────────────────────────────────────────────────────────────
# 10. Resumen
# ─────────────────────────────────────────────────────────────────────
puts "=" * 80
puts "RESUMEN:"
puts "  • SRP: una clase, una razón para cambiar"
puts "  • OCP: extiende sin modificar (nuevas clases, no más if/case)"
puts "  • LSP: las subclases sustituyen al padre sin romper nada"
puts "  • ISP: módulos pequeños y enfocados, no interfaces gigantes"
puts "  • DIP: inyecta dependencias, no las instancies dentro"
puts "  • Strategy: algoritmos intercambiables (en Ruby, a veces basta un bloque)"
puts "  • Factory: centraliza creación compleja"
puts "  • Repository: abstrae acceso a datos"
puts "  • CRITERIO > DOGMA: aplica patrones cuando resuelven problemas reales"
puts "=" * 80
