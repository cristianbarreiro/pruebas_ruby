# frozen_string_literal: true

# = Clases e Instancias
#
# Este archivo cubre los fundamentos de la programación orientada a objetos en Ruby:
# - Definición de clases y creación de instancias
# - Constructores (initialize)
# - Variables de instancia (@var)
# - Métodos de instancia y de clase
# - attr_accessor, attr_reader, attr_writer
# - Encapsulamiento (public, private, protected)
# - Errores comunes al acceder a variables de instancia directamente

puts "=" * 80
puts "CLASES E INSTANCIAS EN RUBY"
puts "=" * 80

# ─────────────────────────────────────────────────────────────────────
# 1. Definición básica de una clase
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 1. Clase básica con initialize ---"

class Dog
  # initialize es el constructor: se llama automáticamente con .new
  def initialize(name, breed)
    # Las variables de instancia (@) pertenecen a cada objeto individual
    @name = name
    @breed = breed
  end

  # Método de instancia: opera sobre un objeto particular
  def bark
    "#{@name} dice: ¡Guau!"
  end

  # Método para inspección legible
  def to_s
    "#{@name} (#{@breed})"
  end
end

fido = Dog.new("Fido", "Labrador")
puts fido            # => Fido (Labrador)  — llama a to_s automáticamente
puts fido.bark       # => Fido dice: ¡Guau!

rex = Dog.new("Rex", "Pastor Alemán")
puts rex.bark        # => Rex dice: ¡Guau!

# Cada instancia tiene su propio estado
puts "fido.object_id: #{fido.object_id}, rex.object_id: #{rex.object_id}"

# ─────────────────────────────────────────────────────────────────────
# 2. attr_accessor, attr_reader, attr_writer
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 2. Accessors ---"

# Estos macros generan métodos getter y/o setter automáticamente.
# - attr_reader   → solo getter (lectura)
# - attr_writer   → solo setter (escritura)
# - attr_accessor → getter + setter (lectura y escritura)

class Person
  attr_reader   :name       # Solo lectura — no se puede cambiar después de crear
  attr_accessor :age        # Lectura y escritura
  attr_writer   :password   # Solo escritura — no se puede leer desde fuera

  def initialize(name, age, password)
    @name = name
    @age = age
    @password = password
  end

  # Método predicado que usa internamente la variable privada
  def authenticated?(attempt)
    @password == attempt
  end
end

person = Person.new("Ana", 30, "secreto123")
puts "Nombre: #{person.name}"        # Getter funciona
puts "Edad: #{person.age}"           # Getter funciona
person.age = 31 # Setter funciona
puts "Edad actualizada: #{person.age}"

# person.name = "Otro"               # ⛔ NoMethodError — attr_reader no genera setter
# puts person.password                # ⛔ NoMethodError — attr_writer no genera getter

puts "¿Autenticación correcta? #{person.authenticated?("secreto123")}"
puts "¿Autenticación incorrecta? #{person.authenticated?("mal")}"

# ─────────────────────────────────────────────────────────────────────
# 3. Métodos de clase vs métodos de instancia
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 3. Métodos de clase vs instancia ---"

class Counter
  # Variable de clase: compartida entre todas las instancias
  # rubocop:disable Style/ClassVars -- se muestra @@ frente a variables de instancia
  @@total_count = 0

  def initialize(label)
    @label = label
    @count = 0
    @@total_count += 1
  end

  # Método de instancia
  def increment
    @count += 1
  end

  def current
    @count
  end

  # Método de clase — se define con self.
  # Se invoca sobre la clase, no sobre una instancia: Counter.total_instances
  def self.total_instances
    @@total_count
  end
  # rubocop:enable Style/ClassVars

  def to_s
    "#{@label}: #{@count}"
  end
end

counter_a = Counter.new("Visitas")
counter_b = Counter.new("Errores")

3.times { counter_a.increment }
counter_b.increment

puts counter_a                        # => Visitas: 3
puts counter_b                        # => Errores: 1
puts "Total instancias creadas: #{Counter.total_instances}" # => 2

# ─────────────────────────────────────────────────────────────────────
# 4. Encapsulamiento: public, private, protected
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 4. Encapsulamiento ---"

class BankAccount
  attr_reader :owner, :balance

  def initialize(owner, initial_balance = 0)
    @owner = owner
    @balance = initial_balance
    @transaction_log = []
  end

  # Métodos públicos — la interfaz que expones al mundo
  def deposit(amount)
    validate_positive!(amount, "depósito")
    @balance += amount
    log_transaction("Depósito", amount)
    self
  end

  def withdraw(amount)
    validate_positive!(amount, "retiro")
    raise InsufficientFundsError, insufficient_funds_message(amount) if amount > @balance

    @balance -= amount
    log_transaction("Retiro", -amount)
    self
  end

  def transfer_to(target_account, amount)
    withdraw(amount)
    target_account.deposit(amount)
    puts "Transferencia de $#{amount} de #{@owner} a #{target_account.owner}"
    self
  end

  def statement
    puts "\n  Estado de cuenta: #{@owner}"
    puts "  #{"─" * 35}"
    @transaction_log.each { |entry| puts "  #{entry}" }
    puts "  #{"─" * 35}"
    puts "  Saldo actual: $#{format("%.2f", @balance)}"
  end

  # protected: accesible desde instancias de la misma clase (o subclases)
  # Útil para comparaciones entre objetos del mismo tipo
  protected

  def balance_for_comparison
    @balance
  end

  # private: solo accesible dentro de la propia instancia
  # Detalles de implementación que no deben exponerse
  private

  def validate_positive!(amount, operation)
    raise ArgumentError, "El monto de #{operation} debe ser positivo, recibido: #{amount}" unless amount.positive?
  end

  def log_transaction(type, amount)
    @transaction_log << "#{Time.now.strftime("%H:%M:%S")} | #{type}: $#{format("%.2f", amount)}"
  end

  def insufficient_funds_message(amount)
    "Fondos insuficientes. Saldo: $#{format("%.2f", @balance)}, Retiro solicitado: $#{format("%.2f", amount)}"
  end
end

# Excepción personalizada para el dominio bancario
class InsufficientFundsError < StandardError; end

# Uso de la cuenta bancaria
account_a = BankAccount.new("Carlos", 1000)
account_b = BankAccount.new("María", 500)

account_a.deposit(500).deposit(200) # Encadenamiento — deposit retorna self
account_a.withdraw(100)
account_a.transfer_to(account_b, 300)

account_a.statement
account_b.statement

# ─────────────────────────────────────────────────────────────────────
# 5. ⚠️ Error común: acceder a variables de instancia sin accessor
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 5. Error común: acceso a variables de instancia ---"

class Broken
  def initialize(value)
    @value = value
  end
  # ⚠️ No definimos attr_reader ni getter para @value
end

broken = Broken.new(42)

# Intentar acceder a @value desde fuera NO lanza error, ¡retorna nil silenciosamente!
# Esto es un error sutil y difícil de depurar.
begin
  # Este patrón NO funciona — Ruby no permite acceder a @vars desde fuera
  # broken.value  # => NoMethodError
  puts "broken.value lanzaría NoMethodError (no hay getter definido)"

  # Con instance_variable_get sí se puede, pero NUNCA lo hagas en producción
  puts "Acceso forzado (antipatrón): #{broken.instance_variable_get(:@value)}"
rescue NoMethodError => e
  puts "Error capturado: #{e.message}"
end

# ─────────────────────────────────────────────────────────────────────
# 6. Variables de instancia no inicializadas retornan nil
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 6. Variables de instancia no inicializadas ---"

class Buggy
  attr_reader :name, :score

  def initialize(name)
    @name = name
    # ⚠️ Olvidamos inicializar @score — será nil
  end

  def display_score
    # Esto NO falla, pero produce resultados inesperados
    "#{@name} tiene #{@score} puntos" # => "Ana tiene  puntos" (nil se convierte a "")
  end

  def double_score
    # ⚠️ ESTO SÍ FALLA: nil no responde a * (NoMethodError)
    @score * 2
  end
end

buggy = Buggy.new("Ana")
puts buggy.display_score # No falla, pero el resultado es confuso

begin
  buggy.double_score
rescue NoMethodError => e
  puts "Error por variable no inicializada: #{e.message}"
  puts "Lección: siempre inicializa todas las variables de instancia en initialize"
end

# ─────────────────────────────────────────────────────────────────────
# 7. Patrón: objetos inmutables con freeze
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 7. Objetos inmutables ---"

class Coordinate
  attr_reader :lat, :lon

  def initialize(lat, lon)
    @lat = lat
    @lon = lon
    freeze # Hace el objeto inmutable después de inicializar
  end

  def to_s
    "(#{@lat}, #{@lon})"
  end
end

point = Coordinate.new(40.4168, -3.7038)
puts "Coordenada: #{point}"

begin
  # No se puede modificar un objeto congelado
  point.instance_variable_set(:@lat, 0)
rescue FrozenError => e
  puts "Error al modificar objeto congelado: #{e.message}"
end

# ─────────────────────────────────────────────────────────────────────
# 8. Data.define — clases de valor modernas (Ruby 3.2+)
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 8. Data.define (Ruby 3.2+) ---"

# Data.define crea clases inmutables, con igualdad por valor, pattern matching, etc.
# Es la forma moderna de crear Value Objects en Ruby.
Money = Data.define(:amount, :currency)

price_a = Money.new(amount: 100, currency: "USD")
price_b = Money.new(amount: 100, currency: "USD")
price_c = Money.new(amount: 200, currency: "EUR")

puts "price_a: #{price_a}"
puts "¿price_a == price_b? #{price_a == price_b}"  # true — igualdad por valor
puts "¿price_a == price_c? #{price_a == price_c}"  # false

# Pattern matching con Data.define
case price_a
in Money[amount: amt, currency: "USD"]
  puts "Precio en dólares: $#{amt}"
in Money[currency: cur]
  puts "Otra moneda: #{cur}"
end

# ─────────────────────────────────────────────────────────────────────
# 9. Resumen
# ─────────────────────────────────────────────────────────────────────
puts "\n#{"=" * 80}"
puts "RESUMEN:"
puts "  • initialize es el constructor, se llama con .new"
puts "  • @variable son variables de instancia (estado del objeto)"
puts "  • attr_reader/writer/accessor generan getters y setters"
puts "  • private/protected controlan el acceso (encapsulamiento)"
puts "  • Las variables de instancia no inicializadas son nil (no error)"
puts "  • Data.define crea value objects inmutables modernos"
puts "  • Siempre inicializa todas las @variables en initialize"
puts "=" * 80
