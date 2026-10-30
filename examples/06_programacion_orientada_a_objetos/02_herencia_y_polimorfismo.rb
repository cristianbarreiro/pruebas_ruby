# frozen_string_literal: true

# = Herencia y Polimorfismo
#
# Este archivo cubre:
# - Herencia de clases (class Child < Parent)
# - Sobreescritura de métodos y uso de super
# - Polimorfismo: mismo mensaje, diferente comportamiento
# - Duck typing: "si camina como pato y hace cuac..."
# - Composición vs herencia (preferir composición)
# - Cuándo usar herencia y cuándo no

puts "=" * 80
puts "HERENCIA Y POLIMORFISMO EN RUBY"
puts "=" * 80

# ─────────────────────────────────────────────────────────────────────
# 1. Herencia básica
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 1. Herencia básica ---"

class Animal
  attr_reader :name, :sound

  def initialize(name, sound)
    @name = name
    @sound = sound
  end

  def speak
    "#{@name} dice: #{@sound}"
  end

  def to_s
    "Animal: #{@name}"
  end
end

class Cat < Animal
  # Hereda initialize, speak, to_s de Animal
  def initialize(name)
    super(name, "Miau") # Llama al initialize de Animal con argumentos específicos
  end

  def purr
    "#{@name} ronronea..." # Método propio de Cat
  end
end

class DogAnimal < Animal
  def initialize(name)
    super(name, "Guau")
  end

  def fetch(item)
    "#{@name} trae el #{item}"
  end
end

cat = Cat.new("Luna")
dog = DogAnimal.new("Max")

puts cat.speak           # => Luna dice: Miau
puts cat.purr            # => Luna ronronea...
puts dog.speak           # => Max dice: Guau
puts dog.fetch("palo")   # => Max trae el palo

# Verificar la cadena de herencia
puts "\nCadena de herencia de Cat:"
puts Cat.ancestors.inspect
# => [Cat, Animal, Object, Kernel, BasicObject]

puts "¿Cat es subclase de Animal? #{Cat < Animal}" # => true

# ─────────────────────────────────────────────────────────────────────
# 2. Sobreescritura de métodos y super
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 2. Sobreescritura y super ---"

class Shape
  attr_reader :color

  def initialize(color = "negro")
    @color = color
  end

  def area
    raise NotImplementedError, "#{self.class} debe implementar #area"
  end

  def describe
    "Soy una figura de color #{@color}"
  end
end

class Circle < Shape
  attr_reader :radius

  def initialize(radius, color = "rojo")
    super(color) # Llama a Shape#initialize con solo el color
    @radius = radius
  end

  def area
    Math::PI * (@radius**2)
  end

  # super llama al método del padre y le agregamos información
  def describe
    "#{super} — Círculo con radio #{@radius}"
  end
end

class Rectangle < Shape
  attr_reader :width, :height

  def initialize(width, height, color = "azul")
    super(color)
    @width = width
    @height = height
  end

  def area
    @width * @height
  end

  def describe
    "#{super} — Rectángulo de #{@width}x#{@height}"
  end
end

class Square < Rectangle
  # Herencia multinivel: Square < Rectangle < Shape
  def initialize(side, color = "verde")
    super(side, side, color) # Un cuadrado es un rectángulo con lados iguales
  end

  def describe
    "#{Shape.instance_method(:describe).bind_call(self)} — Cuadrado de lado #{@width}"
  end
end

circle = Circle.new(5)
rect = Rectangle.new(4, 6)
square = Square.new(3)

puts circle.describe
puts "  Área: #{format("%.2f", circle.area)}"
puts rect.describe
puts "  Área: #{rect.area}"
puts square.describe
puts "  Área: #{square.area}"

# ─────────────────────────────────────────────────────────────────────
# 3. Polimorfismo: mismo mensaje, diferente comportamiento
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 3. Polimorfismo ---"

# Todas las figuras responden a #area y #describe
# El código cliente no necesita saber qué tipo específico es
shapes = [Circle.new(5, "rojo"), Rectangle.new(4, 6, "azul"), Square.new(3, "verde")]

puts "Cálculo de áreas (polimorfismo):"
shapes.each do |shape|
  # No preguntamos "¿eres círculo? ¿eres rectángulo?"
  # Simplemente enviamos el mensaje #area
  puts "  #{shape.describe} → Área: #{format("%.2f", shape.area)}"
end

total_area = shapes.sum(&:area)
puts "  Área total: #{format("%.2f", total_area)}"

# ─────────────────────────────────────────────────────────────────────
# 4. Duck typing: la esencia del polimorfismo en Ruby
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 4. Duck typing ---"

# En Ruby no necesitamos una jerarquía de herencia para polimorfismo.
# Si un objeto responde al mensaje, es suficiente.
# "Si camina como un pato y hace cuac como un pato, entonces es un pato."

class PdfReport
  def render
    "<PDF> Reporte en formato PDF con gráficos y tablas"
  end
end

class HtmlReport
  def render
    "<HTML> Reporte en formato HTML con estilos CSS"
  end
end

class ConsoleReport
  def render
    "[TXT] Reporte en texto plano para la consola"
  end
end

# Esta función no se preocupa por el tipo del reporte.
# Solo necesita que responda a #render (duck typing).
def print_report(report)
  puts "Generando reporte..."
  puts "  #{report.render}"
end

# No comparten herencia, pero todos responden a #render
[PdfReport.new, HtmlReport.new, ConsoleReport.new].each do |report|
  print_report(report)
end

# Verificación de duck typing con respond_to?
def safe_render(report)
  if report.respond_to?(:render)
    report.render
  else
    "⚠️ El objeto #{report.class} no sabe renderizar"
  end
end

puts "\nVerificación con respond_to?:"
puts safe_render(PdfReport.new)
puts safe_render("soy un string") # String no tiene #render

# ─────────────────────────────────────────────────────────────────────
# 5. ⚠️ Problema de herencia mal usada
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 5. Herencia mal usada (antipatrón) ---"

# ⚠️ Antipatrón: heredar solo para reutilizar código
# Un Stack NO ES un Array, aunque quiera usar algunas de sus funciones.

class BadStack < Array
  # Heredar de Array expone métodos que no tienen sentido para un Stack:
  # insert, sort, reverse, [], etc.
  alias peek last
end

bad_stack = BadStack.new
bad_stack.push(1)
bad_stack.push(2)
puts "BadStack peek: #{bad_stack.peek}"

# ⚠️ Esto no debería ser posible en un Stack, pero Array lo permite:
bad_stack.insert(0, 99)
bad_stack.sort!
puts "BadStack roto: #{bad_stack.inspect}"
puts "  → Un Stack no debería permitir insert ni sort"

# ─────────────────────────────────────────────────────────────────────
# 6. Composición sobre herencia (la solución correcta)
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 6. Composición sobre herencia ---"

# ✅ Composición: el Stack TIENE un Array internamente, pero solo expone
# las operaciones que tienen sentido para un Stack.

class GoodStack
  def initialize
    @elements = [] # Composición: usa Array internamente
  end

  def push(element)
    @elements.push(element)
    self
  end

  def pop
    raise "Stack vacío" if empty?

    @elements.pop
  end

  def peek
    raise "Stack vacío" if empty?

    @elements.last
  end

  def empty?
    @elements.empty?
  end

  def size
    @elements.size
  end

  def to_s
    "Stack(#{@elements.join(" → ")})"
  end
end

stack = GoodStack.new
stack.push(1).push(2).push(3)
puts stack # => Stack(1 → 2 → 3)
puts "peek: #{stack.peek}"  # => 3
puts "pop: #{stack.pop}"    # => 3
puts stack # => Stack(1 → 2)

# stack.sort!   # ⛔ NoMethodError — correcto, un Stack no se ordena
# stack[0]      # ⛔ NoMethodError — correcto, no hay acceso por índice

# ─────────────────────────────────────────────────────────────────────
# 7. Ejemplo práctico: sistema de notificaciones con composición
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 7. Sistema de notificaciones (composición) ---"

# Estrategia: diferentes canales de envío (composición + duck typing)
class EmailSender
  def send_notification(recipient, message)
    puts "  📧 Email a #{recipient}: #{message}"
  end
end

class SmsSender
  def send_notification(recipient, message)
    puts "  📱 SMS a #{recipient}: #{message[0..49]}..."
  end
end

class SlackSender
  def send_notification(recipient, message)
    puts "  💬 Slack a ##{recipient}: #{message}"
  end
end

# NotificationService USA (composición) un sender, no HEREDA de él
class NotificationService
  def initialize(sender)
    @sender = sender # Composición: inyectamos la dependencia
  end

  def notify(recipient, message)
    puts "Enviando notificación..."
    @sender.send_notification(recipient, message)
  end

  # Podemos cambiar el sender en tiempo de ejecución
  def change_sender(new_sender)
    @sender = new_sender
  end
end

service = NotificationService.new(EmailSender.new)
service.notify("usuario@mail.com", "Tu pedido fue enviado")

service.change_sender(SlackSender.new)
service.notify("general", "Despliegue completado")

service.change_sender(SmsSender.new)
service.notify("+34612345678", "Código de verificación: 123456 — no compartas este código con nadie")

# ─────────────────────────────────────────────────────────────────────
# 8. Cuándo usar herencia vs composición
# ─────────────────────────────────────────────────────────────────────
puts "\n--- 8. Guía: herencia vs composición ---"

puts <<~GUIDE
  ┌─────────────────────────────────────────────────────────────────┐
  │ HERENCIA (class B < A)                                         │
  │ ✅ Usa cuando hay una relación genuina "es un tipo de"         │
  │    • Circle ES UN Shape                                        │
  │    • Cat ES UN Animal                                          │
  │ ✅ Cuando quieres polimorfismo con comportamiento compartido   │
  │ ⚠️ Máximo 2-3 niveles de profundidad                          │
  │ ⚠️ Ruby solo permite herencia simple (una sola clase padre)    │
  │                                                                │
  │ COMPOSICIÓN (clase TIENE objetos)                              │
  │ ✅ Usa cuando hay una relación "tiene un" o "usa un"           │
  │    • NotificationService USA un Sender                         │
  │    • GoodStack TIENE un Array                                  │
  │ ✅ Más flexible: puedes cambiar componentes en runtime         │
  │ ✅ No acopla la interfaz del componente interno                │
  │ ✅ Preferida en la mayoría de los casos                        │
  │                                                                │
  │ DUCK TYPING                                                    │
  │ ✅ La forma más Ruby de hacer polimorfismo                     │
  │ ✅ No requiere herencia ni interfaces explícitas               │
  │ ✅ Solo requiere que el objeto responda al mensaje             │
  └─────────────────────────────────────────────────────────────────┘
GUIDE

# ─────────────────────────────────────────────────────────────────────
# 9. Resumen
# ─────────────────────────────────────────────────────────────────────
puts "=" * 80
puts "RESUMEN:"
puts "  • Herencia: class Child < Parent (relación 'es un')"
puts "  • super llama al método del padre (con o sin argumentos)"
puts "  • Polimorfismo: mismo mensaje, diferentes implementaciones"
puts "  • Duck typing: no importa el tipo, importa qué mensajes entiende"
puts "  • Composición > herencia en la mayoría de casos"
puts "  • Ruby solo permite herencia simple (usa módulos para compartir)"
puts "=" * 80
