# frozen_string_literal: true

# = Módulos y Mixins
#
# Este archivo cubre:
# - Módulos como namespaces (organización de código)
# - Módulos como mixins (include, extend, prepend)
# - Comparable: ordenamiento natural de objetos
# - Enumerable: iteración personalizada
# - Method Resolution Order (MRO): cómo Ruby busca métodos
# - Mixins prácticos: Printable y Searchable

puts "=" * 80
puts "MÓDULOS Y MIXINS EN RUBY"
puts "=" * 80

# ─────────────────────────────────────────────────────────────────────
# 1. Módulos como namespaces
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 1. Módulos como namespaces ---"

# Los módulos agrupan clases y constantes relacionadas
# para evitar colisiones de nombres.

module Payments
  TAX_RATE = 0.21

  class Invoice
    attr_reader :amount, :description

    def initialize(amount, description)
      @amount = amount
      @description = description
    end

    def total
      @amount * (1 + TAX_RATE)
    end

    def to_s
      "Factura: #{@description} — $#{format("%.2f", @amount)} + IVA = $#{format("%.2f", total)}"
    end
  end

  class Receipt
    def initialize(invoice)
      @invoice = invoice
    end

    def to_s
      "Recibo de pago: #{@invoice.description} — $#{format("%.2f", @invoice.total)}"
    end
  end
end

module Shipping
  class Invoice
    attr_reader :tracking_number

    def initialize(tracking_number)
      @tracking_number = tracking_number
    end

    def to_s
      "Guía de envío: #{@tracking_number}"
    end
  end
end

# Dos clases Invoice sin conflicto gracias a los namespaces
payment_invoice = Payments::Invoice.new(100, "Consultoría")
shipping_invoice = Shipping::Invoice.new("MX-2024-ABC123")

puts payment_invoice
puts Payments::Receipt.new(payment_invoice)
puts shipping_invoice
puts "Tasa IVA: #{Payments::TAX_RATE}"

# ─────────────────────────────────────────────────────────────────────
# 2. Módulos como mixins: include
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 2. include — Métodos de instancia ---"

# include agrega métodos del módulo como métodos de INSTANCIA.
# Es la forma más común de usar mixins.

module Greetable
  def greet
    "¡Hola! Soy #{name_for_greeting}"
  end

  private

  # El módulo define un contrato: la clase que lo incluye debe implementar esto
  def name_for_greeting
    raise NotImplementedError, "#{self.class} debe implementar #name_for_greeting"
  end
end

module Farewell
  def say_goodbye
    "¡Adiós de parte de #{name_for_greeting}!"
  end

  private

  def name_for_greeting
    raise NotImplementedError, "#{self.class} debe implementar #name_for_greeting"
  end
end

class Employee
  include Greetable
  include Farewell

  attr_reader :name, :role

  def initialize(name, role)
    @name = name
    @role = role
  end

  private

  # Implementa el contrato de ambos mixins
  def name_for_greeting
    "#{@name} (#{@role})"
  end
end

employee = Employee.new("María", "Desarrolladora")
puts employee.greet
puts employee.say_goodbye

# ─────────────────────────────────────────────────────────────────────
# 3. extend — Métodos de clase
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 3. extend — Métodos de clase ---"

# extend agrega métodos del módulo como métodos de CLASE (singleton methods).

module ClassInfo
  def describe_class
    "Clase #{name} con #{instance_methods(false).count} métodos propios"
  end

  def class_version
    "1.0.0"
  end
end

class Product
  extend ClassInfo # Los métodos se agregan a la clase, no a las instancias

  attr_reader :title, :price

  def initialize(title, price)
    @title = title
    @price = price
  end
end

puts Product.describe_class # Método de clase
puts "Versión: #{Product.class_version}"
# product = Product.new("Laptop", 999)
# product.describe_class  # ⛔ NoMethodError — es método de clase, no de instancia

# ─────────────────────────────────────────────────────────────────────
# 4. prepend — Sobreescribir con prioridad
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 4. prepend — Interceptar métodos ---"

# prepend inserta el módulo ANTES de la clase en la cadena de búsqueda.
# Útil para logging, validación, memoización, etc.

module Logging
  def process(data)
    puts "  [LOG] #{self.class}#process llamado con: #{data.inspect}"
    result = super  # Llama al método original de la clase
    puts "  [LOG] Resultado: #{result.inspect}"
    result
  end
end

module Timing
  def process(data)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = super  # Llama al siguiente en la cadena (Logging#process o la clase)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    puts "  [TIME] Tardó #{format("%.6f", elapsed)}s"
    result
  end
end

class DataProcessor
  prepend Timing   # Se ejecuta primero (más externo)
  prepend Logging  # Se ejecuta segundo

  def process(data)
    data.map { |item| item.to_s.upcase }
  end
end

puts "Cadena de resolución:"
puts "  #{DataProcessor.ancestors[0..4].inspect}"
# => [Logging, Timing, DataProcessor, ...]

processor = DataProcessor.new
processor.process(%w[hello world])

# ─────────────────────────────────────────────────────────────────────
# 5. Comparable — Ordenamiento natural
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 5. Comparable ---"

# Al incluir Comparable e implementar <=>, obtienes:
# <, <=, ==, >=, >, between?, clamp

class Temperature
  include Comparable

  attr_reader :degrees, :scale

  def initialize(degrees, scale = :celsius)
    @degrees = degrees
    @scale = scale
  end

  # El único método que debes implementar para Comparable
  def <=>(other)
    to_celsius <=> other.to_celsius
  end

  def to_celsius
    case @scale
    when :celsius    then @degrees
    when :fahrenheit then (@degrees - 32) * 5.0 / 9
    when :kelvin     then @degrees - 273.15
    end
  end

  def to_s
    "#{@degrees}°#{@scale.to_s[0].upcase}"
  end
end

temp_a = Temperature.new(100, :celsius)
temp_b = Temperature.new(212, :fahrenheit)
temp_c = Temperature.new(373.15, :kelvin)
temp_d = Temperature.new(20, :celsius)

puts "#{temp_a} == #{temp_b}? #{temp_a == temp_b}"   # true (100°C == 212°F)
puts "#{temp_a} == #{temp_c}? #{temp_a == temp_c}"   # true (100°C == 373.15K)
puts "#{temp_d} < #{temp_a}? #{temp_d < temp_a}"     # true

temps = [temp_a, temp_d, Temperature.new(50, :celsius)]
puts "Ordenadas: #{temps.sort.join(", ")}"
puts "Máxima: #{temps.max}"
puts "Mínima: #{temps.min}"

# ─────────────────────────────────────────────────────────────────────
# 6. Enumerable — Iteración personalizada
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 6. Enumerable ---"

# Al incluir Enumerable e implementar #each, obtienes:
# map, select, reject, find, reduce, sort, min, max, count, any?, all?, etc.
# ¡Más de 50 métodos gratis!

class NumberRange
  include Enumerable

  def initialize(start_val, end_val)
    @start_val = start_val
    @end_val = end_val
  end

  # El único método que debes implementar para Enumerable
  def each(&block)
    current = @start_val
    while current <= @end_val
      block.call(current)
      current += 1
    end
  end
end

range = NumberRange.new(1, 10)

puts "Todos: #{range.to_a.inspect}"
puts "Pares: #{range.select(&:even?).inspect}"
puts "Suma:  #{range.reduce(:+)}"
puts "Max:   #{range.max}"
puts "¿Incluye 5? #{range.include?(5)}"
puts "Primeros 3: #{range.first(3).inspect}"
puts "Cuadrados: #{range.map { |num| num**2 }.inspect}"

# ─────────────────────────────────────────────────────────────────────
# 7. Ejemplo práctico: colección con Enumerable
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 7. Colección personalizada ---"

class TaskList
  include Enumerable

  Task = Data.define(:title, :priority, :completed)

  def initialize
    @tasks = []
  end

  def add(title, priority: :normal, completed: false)
    @tasks << Task.new(title: title, priority: priority, completed: completed)
    self
  end

  # Implementar each para obtener todos los métodos de Enumerable
  def each(&)
    @tasks.each(&)
  end

  def pending
    reject(&:completed)
  end

  def by_priority
    priority_order = { high: 0, normal: 1, low: 2 }
    sort_by { |task| priority_order.fetch(task.priority, 99) }
  end
end

tasks = TaskList.new
tasks
  .add("Desplegar a producción", priority: :high)
  .add("Escribir tests", priority: :high, completed: true)
  .add("Revisar PR", priority: :normal)
  .add("Actualizar README", priority: :low)
  .add("Refactorizar módulo X", priority: :normal, completed: true)

puts "Total tareas: #{tasks.count}"
puts "Pendientes: #{tasks.pending.count}"
puts "¿Alguna de alta prioridad? #{tasks.any? { |tsk| tsk.priority == :high }}"
puts "Todas completadas? #{tasks.all?(&:completed)}"

puts "\nTareas por prioridad:"
tasks.by_priority.each do |task|
  status = task.completed ? "✅" : "⬜"
  puts "  #{status} [#{task.priority}] #{task.title}"
end

# ─────────────────────────────────────────────────────────────────────
# 8. Method Resolution Order (MRO)
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 8. Method Resolution Order (MRO) ---"

# Ruby busca métodos en este orden:
# 1. Módulos prepended (último prepended primero)
# 2. La propia clase
# 3. Módulos included (último included primero)
# 4. Clase padre
# 5. Repetir 1-4 para la clase padre
# 6. Object → Kernel → BasicObject

module ModA
  def who_am_i
    "ModA"
  end
end

module ModB
  def who_am_i
    "ModB"
  end
end

module ModC
  def who_am_i
    "ModC (prepended)"
  end
end

class Base
  def who_am_i
    "Base"
  end
end

class Child < Base
  include ModA
  include ModB      # ModB se incluye después, tiene prioridad sobre ModA
  prepend ModC      # prepend tiene prioridad sobre todo (excepto otro prepend posterior)
end

puts "Child.ancestors:"
Child.ancestors.each_with_index do |ancestor, idx|
  puts "  #{idx}. #{ancestor}"
  break if ancestor == BasicObject
end

child = Child.new
puts "\nchild.who_am_i → #{child.who_am_i}" # => "ModC (prepended)"
puts "  (ModC gana porque fue prepended)"

# ─────────────────────────────────────────────────────────────────────
# 9. Mixins prácticos: Searchable y Formattable
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 9. Mixins prácticos ---"

# Mixin que agrega búsqueda a cualquier colección
module Searchable
  def search(query)
    select { |item| item.matches?(query) }
  end

  def search_first(query)
    find { |item| item.matches?(query) }
  end
end

# Mixin que agrega formateo
module Formattable
  def to_table
    return "  (vacío)" if empty_collection?

    header = table_headers.join(" | ")
    separator = "-" * header.length
    rows = table_rows.map { |row| row.join(" | ") }
    [header, separator, *rows].map { |line| "  #{line}" }.join("\n")
  end

  private

  def empty_collection?
    respond_to?(:empty?) ? empty? : false
  end
end

class BookCollection
  include Enumerable
  include Searchable
  include Formattable

  Book = Data.define(:title, :author, :year) do
    def matches?(query)
      query_down = query.downcase
      title.downcase.include?(query_down) || author.downcase.include?(query_down)
    end
  end

  def initialize
    @books = []
  end

  def add(title, author, year)
    @books << Book.new(title: title, author: author, year: year)
    self
  end

  def each(&)
    @books.each(&)
  end

  private

  def table_headers
    %w[Título Autor Año]
  end

  def table_rows
    @books.map { |book| [book.title.ljust(30), book.author.ljust(20), book.year.to_s] }
  end
end

library = BookCollection.new
library
  .add("El Quijote", "Cervantes", 1605)
  .add("Cien Años de Soledad", "García Márquez", 1967)
  .add("La Casa de los Espíritus", "Isabel Allende", 1982)
  .add("Rayuela", "Julio Cortázar", 1963)

puts "Catálogo completo:"
puts library.to_table

puts "\nBuscar 'García':"
library.search("García").each { |book| puts "  📖 #{book.title} (#{book.year})" }

puts "\nLibros después de 1960:"
recent = library.select { |book| book.year > 1960 }
puts "  #{recent.map(&:title).join(", ")}"

puts "\nMás antiguo: #{library.min_by(&:year).title}"

# ─────────────────────────────────────────────────────────────────────
# 10. Resumen
# ─────────────────────────────────────────────────────────────────────
puts "\n#{"=" * 80}"
puts "RESUMEN:"
puts "  • Módulos como namespaces: organizan código y evitan colisiones"
puts "  • include: agrega métodos de instancia (mixin más común)"
puts "  • extend: agrega métodos de clase"
puts "  • prepend: intercepta métodos (logging, validación, etc.)"
puts "  • Comparable: implementa <=> y obtén <, >, ==, between?, etc."
puts "  • Enumerable: implementa each y obtén map, select, reduce, etc."
puts "  • MRO: prepend > clase > include (último incluido primero) > padre"
puts "  • Los mixins son la alternativa de Ruby a la herencia múltiple"
puts "=" * 80
