# frozen_string_literal: true

# = Excepciones y Validación
#
# Este archivo cubre:
# - begin/rescue/else/ensure (manejo completo de errores)
# - Excepciones personalizadas con jerarquía
# - Propagación de errores
# - Validación de inputs
# - Diferencia entre errores de programación y errores de dominio
# - Manejo seguro de archivos
# - Mensajes de error útiles
# - Testing de happy path y sad path

puts "=" * 80
puts "EXCEPCIONES Y VALIDACIÓN EN RUBY"
puts "=" * 80

# ─────────────────────────────────────────────────────────────────────
# 1. begin/rescue/else/ensure — El flujo completo
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 1. begin/rescue/else/ensure ---"

def divide(dividend, divisor)
  begin
    result = dividend / divisor
  rescue ZeroDivisionError => err
    # rescue: se ejecuta si ocurre el error especificado
    puts "  ⚠️ Error capturado: #{err.message}"
    nil
  rescue TypeError => err
    # Puedes capturar diferentes tipos de error
    puts "  ⚠️ Error de tipo: #{err.message}"
    nil
  else
    # else: se ejecuta SOLO si NO hubo error (a menudo olvidado)
    puts "  ✅ División exitosa: #{dividend} / #{divisor} = #{result}"
    result
  ensure
    # ensure: se ejecuta SIEMPRE, haya o no error (como finally en otros lenguajes)
    puts "  [ensure] Operación de división finalizada"
  end
end

divide(10, 2)     # Happy path
divide(10, 0)     # Sad path: ZeroDivisionError
divide(10, "a")   # Sad path: TypeError

# ─────────────────────────────────────────────────────────────────────
# 2. Excepciones personalizadas con jerarquía
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 2. Excepciones personalizadas ---"

# ✅ Buena práctica: crear una jerarquía de excepciones para tu dominio.
# Todas heredan de StandardError (no de Exception).

# Error base de la aplicación
class AppError < StandardError; end

# Errores de validación
class ValidationError < AppError
  attr_reader :field, :value

  def initialize(field, value, message = nil)
    @field = field
    @value = value
    super(message || "Validación fallida para '#{field}': valor inválido '#{value}'")
  end
end

class RequiredFieldError < ValidationError
  def initialize(field)
    super(field, nil, "El campo '#{field}' es obligatorio")
  end
end

class InvalidFormatError < ValidationError
  def initialize(field, value, expected_format)
    super(field, value, "El campo '#{field}' tiene formato inválido: '#{value}'. Esperado: #{expected_format}")
  end
end

# Errores de negocio
class BusinessError < AppError; end

class InsufficientBalanceError < BusinessError
  attr_reader :available, :requested

  def initialize(available, requested)
    @available = available
    @requested = requested
    super("Saldo insuficiente: disponible $#{"%.2f" % available}, solicitado $#{"%.2f" % requested}")
  end
end

class AccountLockedError < BusinessError
  def initialize(reason = "Cuenta bloqueada por seguridad")
    super(reason)
  end
end

# Demostración de la jerarquía
puts "Jerarquía de excepciones:"
puts "  AppError"
puts "    ├── ValidationError"
puts "    │     ├── RequiredFieldError"
puts "    │     └── InvalidFormatError"
puts "    └── BusinessError"
puts "          ├── InsufficientBalanceError"
puts "          └── AccountLockedError"

# ─────────────────────────────────────────────────────────────────────
# 3. Validación de inputs
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 3. Validación de inputs ---"

class UserRegistration
  EMAIL_PATTERN = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  MIN_PASSWORD_LENGTH = 8

  def register(name: nil, email: nil, password: nil)
    validate_presence!(name, "nombre")
    validate_presence!(email, "email")
    validate_presence!(password, "contraseña")
    validate_email!(email)
    validate_password!(password)

    # Si llegamos aquí, todo es válido
    puts "  ✅ Usuario '#{name}' registrado con #{email}"
    { name: name, email: email, status: :active }
  end

  private

  def validate_presence!(value, field)
    raise RequiredFieldError, field if value.nil? || value.to_s.strip.empty?
  end

  def validate_email!(email)
    return if email.match?(EMAIL_PATTERN)

    raise InvalidFormatError.new("email", email, "usuario@dominio.com")
  end

  def validate_password!(password)
    return if password.length >= MIN_PASSWORD_LENGTH

    raise ValidationError.new(
      "contraseña",
      "***",
      "La contraseña debe tener al menos #{MIN_PASSWORD_LENGTH} caracteres (tiene #{password.length})"
    )
  end
end

registration = UserRegistration.new

# Happy path
registration.register(name: "Ana", email: "ana@mail.com", password: "segura123")

# Sad paths — probamos cada validación
test_cases = [
  { name: nil, email: "a@b.com", password: "12345678", expected_error: "nombre" },
  { name: "Ana", email: "no-es-email", password: "12345678", expected_error: "formato" },
  { name: "Ana", email: "a@b.com", password: "corta", expected_error: "longitud" }
]

test_cases.each do |test_case|
  registration.register(
    name: test_case[:name],
    email: test_case[:email],
    password: test_case[:password]
  )
rescue ValidationError => err
  puts "  ❌ Error esperado (#{test_case[:expected_error]}): #{err.message}"
end

# ─────────────────────────────────────────────────────────────────────
# 4. Captura por jerarquía
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 4. Captura por jerarquía ---"

def handle_error(error_instance)
  raise error_instance
rescue ValidationError => err
  # Captura RequiredFieldError, InvalidFormatError y ValidationError
  puts "  [Validación] #{err.class}: #{err.message}"
rescue BusinessError => err
  # Captura InsufficientBalanceError y AccountLockedError
  puts "  [Negocio] #{err.class}: #{err.message}"
rescue AppError => err
  # Captura cualquier error de la app no manejado antes
  puts "  [App] #{err.class}: #{err.message}"
end

handle_error(RequiredFieldError.new("email"))
handle_error(InsufficientBalanceError.new(50.0, 100.0))
handle_error(AccountLockedError.new)

# ⚠️ Orden importante: de más específico a más general
puts "\n  💡 Siempre captura excepciones de la más específica a la más general."
puts "     Si pones AppError primero, nunca llegarás a ValidationError."

# ─────────────────────────────────────────────────────────────────────
# 5. Errores de programación vs errores de dominio
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 5. Errores de programación vs errores de dominio ---"

puts <<~EXPLANATION
  ┌─────────────────────────────────────────────────────────────────┐
  │ ERRORES DE PROGRAMACIÓN (bugs)                                 │
  │ • NoMethodError, TypeError, NameError, ArgumentError           │
  │ • NO deberías rescatarlos en producción (excepto logging)      │
  │ • Indica que hay un bug que debes corregir                     │
  │ • Ejemplo: llamar un método que no existe                      │
  │                                                                │
  │ ERRORES DE DOMINIO (situaciones esperadas)                     │
  │ • InsufficientBalanceError, ValidationError, NotFoundError     │
  │ • SÍ deberías manejarlos — son parte del flujo normal          │
  │ • El usuario puede causar estos errores con datos válidos      │
  │ • Ejemplo: saldo insuficiente para una transferencia           │
  └─────────────────────────────────────────────────────────────────┘
EXPLANATION

# ⚠️ Antipatrón: rescatar Exception o todos los errores
puts "⚠️ Antipatrón — NUNCA hagas esto:"
puts '  rescue Exception => e  # Captura CTRL+C, NoMemoryError, SyntaxError...'
puts '  rescue => e            # Rescata StandardError — aceptable pero usa clases específicas'

# ─────────────────────────────────────────────────────────────────────
# 6. Manejo seguro de archivos
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 6. Manejo seguro de archivos ---"

# ✅ Patrón correcto: usar bloques que cierran automáticamente
def read_config(file_path)
  content = File.read(file_path)
  puts "  ✅ Archivo leído: #{content.length} bytes"
  content
rescue Errno::ENOENT => err
  puts "  ❌ Archivo no encontrado: #{file_path}"
  puts "     Detalle: #{err.message}"
  nil
rescue Errno::EACCES => err
  puts "  ❌ Sin permisos para leer: #{file_path}"
  puts "     Detalle: #{err.message}"
  nil
end

# Intentar leer un archivo que no existe
read_config("config_inexistente.yml")

# ✅ Escritura segura con bloque (se cierra automáticamente)
def write_safely(file_path, content)
  # Escribir a un archivo temporal primero, luego renombrar
  temp_path = "#{file_path}.tmp"
  File.write(temp_path, content)
  File.rename(temp_path, file_path)
  puts "  ✅ Archivo escrito: #{file_path}"
  true
rescue SystemCallError => err
  # SystemCallError es padre de todos los Errno::*
  puts "  ❌ Error de sistema al escribir: #{err.message}"
  # Limpiar archivo temporal si existe
  File.delete(temp_path) if temp_path && File.exist?(temp_path)
  false
end

# ─────────────────────────────────────────────────────────────────────
# 7. Propagación de errores (re-raise)
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 7. Propagación de errores ---"

# A veces capturas un error para agregar contexto y luego lo re-lanzas.

class PaymentProcessor
  def process_payment(amount, card_number)
    validate_amount!(amount)
    charge_card(card_number, amount)
    puts "  ✅ Pago de $#{"%.2f" % amount} procesado"
  rescue ValidationError
    raise  # Re-lanzar sin modificar — el error ya tiene buen contexto
  rescue StandardError => err
    # Envolver el error original en uno con más contexto
    raise BusinessError, "Error al procesar pago de $#{"%.2f" % amount}: #{err.message}"
  end

  private

  def validate_amount!(amount)
    raise ValidationError.new("monto", amount, "El monto debe ser positivo") unless amount.positive?
  end

  def charge_card(card_number, amount)
    # Simular un error de red
    raise IOError, "Timeout conectando al procesador de pagos" if card_number == "FAIL"

    puts "  💳 Cargando $#{"%.2f" % amount} a tarjeta ***#{card_number[-4..]}"
  end
end

payment = PaymentProcessor.new

# Happy path
payment.process_payment(99.99, "4111111111111234")

# Sad path: error de validación (se propaga directamente)
begin
  payment.process_payment(-50, "4111111111111234")
rescue ValidationError => err
  puts "  ❌ Validación: #{err.message}"
end

# Sad path: error envuelto con contexto adicional
begin
  payment.process_payment(75, "FAIL")
rescue BusinessError => err
  puts "  ❌ Negocio: #{err.message}"
end

# ─────────────────────────────────────────────────────────────────────
# 8. retry — Reintentar operaciones transitorias
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 8. retry con límite ---"

def fetch_with_retry(url, max_retries: 3)
  attempts = 0

  begin
    attempts += 1
    puts "  Intento #{attempts} para #{url}..."

    # Simular falla transitoria (falla las primeras 2 veces)
    raise IOError, "Conexión rechazada" if attempts < 3

    puts "  ✅ Respuesta recibida en intento #{attempts}"
    "datos del servidor"
  rescue IOError => err
    if attempts < max_retries
      wait_time = 2**attempts * 0.01  # Backoff exponencial (simulado rápido)
      puts "  ⚠️ #{err.message} — reintentando en #{"%.2f" % wait_time}s..."
      sleep(wait_time)
      retry  # Vuelve al begin
    else
      puts "  ❌ Falló después de #{max_retries} intentos"
      raise  # Re-lanza si agotamos reintentos
    end
  end
end

fetch_with_retry("https://api.example.com/data")

# ─────────────────────────────────────────────────────────────────────
# 9. Mensajes de error útiles
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 9. Mensajes de error útiles ---"

puts <<~MESSAGES
  ┌─────────────────────────────────────────────────────────────────┐
  │ MENSAJES DE ERROR — QUÉ INCLUIR                               │
  │                                                                │
  │ ❌ Malo:  "Error"                                              │
  │ ❌ Malo:  "Valor inválido"                                     │
  │ ❌ Malo:  "Algo salió mal"                                     │
  │                                                                │
  │ ✅ Bueno: "El email 'foo' no tiene formato válido.             │
  │           Esperado: usuario@dominio.com"                       │
  │                                                                │
  │ ✅ Bueno: "Saldo insuficiente: disponible $50.00,              │
  │           solicitado $100.00"                                   │
  │                                                                │
  │ Un buen mensaje de error incluye:                              │
  │ 1. QUÉ falló (qué operación, qué campo)                       │
  │ 2. POR QUÉ falló (qué regla se violó)                         │
  │ 3. QUÉ HACER (valor esperado, acción correctiva)              │
  └─────────────────────────────────────────────────────────────────┘
MESSAGES

# ─────────────────────────────────────────────────────────────────────
# 10. Testing de happy y sad paths
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 10. Testing de happy y sad paths ---"

# Framework de testing mínimo para demostración
def assert_equal(expected, actual, description)
  if expected == actual
    puts "  ✅ PASS: #{description}"
  else
    puts "  ❌ FAIL: #{description}"
    puts "       Esperado: #{expected.inspect}"
    puts "       Obtenido: #{actual.inspect}"
  end
end

def assert_raises(error_class, description, &block)
  block.call
  puts "  ❌ FAIL: #{description} — no lanzó #{error_class}"
rescue error_class => err
  puts "  ✅ PASS: #{description} — #{err.message}"
rescue StandardError => err
  puts "  ❌ FAIL: #{description} — lanzó #{err.class} en vez de #{error_class}"
end

puts "\nTests del sistema de registro:"

reg = UserRegistration.new

# Happy paths
assert_equal(
  :active,
  reg.register(name: "Ana", email: "ana@mail.com", password: "12345678")[:status],
  "Registro exitoso retorna status :active"
)

# Sad paths — cada validación tiene su test
assert_raises(RequiredFieldError, "Nombre vacío lanza RequiredFieldError") do
  reg.register(name: "", email: "a@b.com", password: "12345678")
end

assert_raises(RequiredFieldError, "Email nil lanza RequiredFieldError") do
  reg.register(name: "Ana", email: nil, password: "12345678")
end

assert_raises(InvalidFormatError, "Email sin @ lanza InvalidFormatError") do
  reg.register(name: "Ana", email: "sin-arroba", password: "12345678")
end

assert_raises(ValidationError, "Contraseña corta lanza ValidationError") do
  reg.register(name: "Ana", email: "a@b.com", password: "corta")
end

puts "\nTests del procesador de pagos:"

pay = PaymentProcessor.new

assert_raises(ValidationError, "Monto negativo lanza ValidationError") do
  pay.process_payment(-1, "4111111111111234")
end

assert_raises(BusinessError, "Error de red se envuelve en BusinessError") do
  pay.process_payment(100, "FAIL")
end

# ─────────────────────────────────────────────────────────────────────
# 11. Resumen
# ─────────────────────────────────────────────────────────────────────
puts "\n#{"=" * 80}"
puts "RESUMEN:"
puts "  • begin/rescue/else/ensure — else ejecuta si NO hay error"
puts "  • Crea excepciones personalizadas heredando de StandardError"
puts "  • Jerarquía: captura de más específica a más general"
puts "  • Errores de programación (bugs) ≠ errores de dominio (esperados)"
puts "  • NUNCA rescates Exception — solo StandardError o subclases"
puts "  • retry con límite para errores transitorios (red, timeouts)"
puts "  • Mensajes de error: QUÉ falló + POR QUÉ + QUÉ HACER"
puts "  • Testea tanto happy paths como sad paths"
puts "  • Usa bloques para archivos (se cierran automáticamente)"
puts "=" * 80
