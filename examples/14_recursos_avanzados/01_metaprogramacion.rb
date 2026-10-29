# frozen_string_literal: true

# = Metaprogramación
#
# La metaprogramación es la capacidad de un programa de modificar su propia
# estructura en tiempo de ejecución. Ruby es famoso por sus potentes
# capacidades de metaprogramación, pero deben usarse con responsabilidad.
#
# ⚠️  ADVERTENCIA: La metaprogramación excesiva produce código difícil de
# entender, depurar y mantener. Úsala solo cuando aporte claridad o elimine
# duplicación significativa. "Con gran poder viene gran responsabilidad."

puts "=" * 70
puts " METAPROGRAMACIÓN EN RUBY"
puts "=" * 70

# ──────────────────────────────────────────────────────────────────────────────
# 1. Introspección básica - Conocer el sistema en tiempo de ejecución
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 1. Introspección básica ──"

class Animal
  attr_reader :nombre

  def initialize(nombre:)
    @nombre = nombre
  end

  def hablar
    "..."
  end
end

class Perro < Animal
  def hablar
    "¡Guau!"
  end

  def fetch(objeto)
    "#{nombre} trae #{objeto}"
  end
end

rex = Perro.new(nombre: "Rex")

# is_a? / kind_of? - Verificar tipo (incluye herencia)
puts "  rex.is_a?(Perro):  #{rex.is_a?(Perro)}"    # true
puts "  rex.is_a?(Animal): #{rex.is_a?(Animal)}"    # true
puts "  rex.is_a?(String): #{rex.is_a?(String)}"    # false

# class e instance_of? - Clase exacta (sin herencia)
puts "  rex.class:                    #{rex.class}"                    # Perro
puts "  rex.instance_of?(Perro):      #{rex.instance_of?(Perro)}"     # true
puts "  rex.instance_of?(Animal):     #{rex.instance_of?(Animal)}"    # false

# respond_to? - ¿Puede responder a este mensaje?
puts "  rex.respond_to?(:hablar):     #{rex.respond_to?(:hablar)}"    # true
puts "  rex.respond_to?(:volar):      #{rex.respond_to?(:volar)}"     # false

# ancestors - Cadena de herencia completa
puts "  Perro.ancestors: #{Perro.ancestors.inspect}"

# methods - Listar métodos disponibles
metodos_propios = rex.methods - Object.instance_methods
puts "  Métodos propios de rex: #{metodos_propios.sort.inspect}"

# ──────────────────────────────────────────────────────────────────────────────
# 2. send y public_send - Invocar métodos dinámicamente
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 2. send y public_send ──"

# send puede invocar cualquier método, incluso privados
# public_send solo invoca métodos públicos (más seguro)

class Calculadora
  def sumar(val_a, val_b)
    val_a + val_b
  end

  private

  def secreto
    "información privada"
  end
end

calc = Calculadora.new

# Invocar método público dinámicamente
metodo = :sumar
puts "  calc.public_send(:sumar, 3, 5): #{calc.public_send(metodo, 3, 5)}"

# send puede acceder a métodos privados (⚠️  rompe encapsulación)
puts "  calc.send(:secreto): #{calc.send(:secreto)}"

# public_send respeta la visibilidad (✅  más seguro)
begin
  calc.public_send(:secreto)
rescue NoMethodError => err
  puts "  calc.public_send(:secreto) → Error: #{err.message}"
end

# Caso práctico: dispatch dinámico
operaciones = { sumar: [10, 20] }
operaciones.each do |operacion, args|
  resultado = calc.public_send(operacion, *args)
  puts "  #{operacion}(#{args.join(', ')}) = #{resultado}"
end

# ──────────────────────────────────────────────────────────────────────────────
# 3. define_method - Crear métodos dinámicamente
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 3. define_method ──"

class Configuracion
  OPCIONES = %i[color tamano fuente idioma].freeze

  # Crear getters y setters dinámicamente para cada opción
  OPCIONES.each do |opcion|
    # Define un setter: set_color(val), set_tamano(val), etc.
    define_method(:"set_#{opcion}") do |valor|
      instance_variable_set(:"@#{opcion}", valor)
    end

    # Define un getter: color, tamano, etc.
    define_method(opcion) do
      instance_variable_get(:"@#{opcion}")
    end

    # Define un predicado: color?, tamano?, etc.
    define_method(:"#{opcion}?") do
      !instance_variable_get(:"@#{opcion}").nil?
    end
  end
end

config = Configuracion.new
config.set_color("azul")
config.set_tamano(14)

puts "  config.color:   #{config.color}"
puts "  config.tamano:  #{config.tamano}"
puts "  config.color?:  #{config.color?}"
puts "  config.fuente?: #{config.fuente?}"

# Verificar que los métodos existen
puts "  Métodos set_*: #{Configuracion.instance_methods.grep(/^set_/).sort.inspect}"

# ──────────────────────────────────────────────────────────────────────────────
# 4. method_missing y respond_to_missing?
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 4. method_missing y respond_to_missing? ──"

# ⚠️  REGLA: Siempre implementar respond_to_missing? junto con method_missing.
# Si no lo haces, respond_to? retornará false para métodos que sí manejas.

class FlexibleHash
  def initialize(datos = {})
    @datos = datos
  end

  # Intercepta llamadas a métodos que no existen
  def method_missing(nombre_metodo, *args)
    nombre_str = nombre_metodo.to_s

    if nombre_str.end_with?("=")
      # Setter: obj.clave = valor
      clave = nombre_str.chomp("=").to_sym
      @datos[clave] = args.first
    elsif @datos.key?(nombre_str.to_sym)
      # Getter: obj.clave
      @datos[nombre_str.to_sym]
    else
      # ¡IMPORTANTE! Delegar a super si no manejamos el método
      super
    end
  end

  # ✅ SIEMPRE implementar junto con method_missing
  def respond_to_missing?(nombre_metodo, include_private = false)
    nombre_str = nombre_metodo.to_s
    nombre_str.end_with?("=") || @datos.key?(nombre_str.to_sym) || super
  end

  def to_s
    @datos.inspect
  end
end

flexible = FlexibleHash.new(nombre: "Ruby", version: 3)
puts "  flexible.nombre:  #{flexible.nombre}"
puts "  flexible.version: #{flexible.version}"

flexible.nuevo_campo = "valor dinámico"
puts "  flexible.nuevo_campo: #{flexible.nuevo_campo}"

# respond_to? funciona correctamente gracias a respond_to_missing?
puts "  respond_to?(:nombre):      #{flexible.respond_to?(:nombre)}"
puts "  respond_to?(:inexistente): #{flexible.respond_to?(:inexistente)}"

# method también funciona
metodo_nombre = flexible.method(:nombre)
puts "  flexible.method(:nombre):  #{metodo_nombre.call}"

# Sin respond_to_missing?, esto fallaría:
begin
  flexible.metodo_que_no_existe
rescue NoMethodError => err
  puts "  NoMethodError esperado: #{err.message.split("\n").first}"
end

# ──────────────────────────────────────────────────────────────────────────────
# 5. instance_variable_get / instance_variable_set
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 5. instance_variable_get/set ──"

class Persona
  def initialize(nombre:, edad:)
    @nombre = nombre
    @edad = edad
  end

  def to_s
    "#{@nombre} (#{@edad} años)"
  end
end

persona = Persona.new(nombre: "Ana", edad: 30)

# Leer variables de instancia (⚠️  rompe encapsulación)
puts "  @nombre: #{persona.instance_variable_get(:@nombre)}"
puts "  @edad:   #{persona.instance_variable_get(:@edad)}"

# Escribir variables de instancia
persona.instance_variable_set(:@edad, 31)
puts "  Después de set @edad: #{persona}"

# Listar todas las variables de instancia
puts "  Variables de instancia: #{persona.instance_variables.inspect}"

# ⚠️  Esto funciona pero es mala práctica en producción.
# Útil para: testing, serialización, frameworks.

# ──────────────────────────────────────────────────────────────────────────────
# 6. class_eval / module_eval - Evaluar código en contexto de clase
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 6. class_eval / module_eval ──"

# class_eval abre una clase existente y permite agregar métodos
class Vehiculo
  attr_reader :marca

  def initialize(marca:)
    @marca = marca
  end
end

# Agregar un método a Vehiculo desde fuera de su definición
Vehiculo.class_eval do
  def descripcion
    "Vehículo marca #{marca}"
  end

  # También podemos definir métodos de clase
  def self.tipo
    "Transporte"
  end
end

auto = Vehiculo.new(marca: "Toyota")
puts "  auto.descripcion: #{auto.descripcion}"
puts "  Vehiculo.tipo:    #{Vehiculo.tipo}"

# module_eval es alias de class_eval (funciona igual)
String.class_eval do
  def gritar
    upcase + "!!!"
  end
end

puts '  "hola".gritar: ' + "hola".gritar

# ──────────────────────────────────────────────────────────────────────────────
# 7. instance_eval - Evaluar en contexto de una instancia
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 7. instance_eval ──"

class Cofre
  def initialize
    @tesoro = "diamante"
  end

  private

  def abrir
    "¡Cofre abierto! Contiene: #{@tesoro}"
  end
end

cofre = Cofre.new

# instance_eval permite acceder a métodos privados y variables de instancia
resultado_eval = cofre.instance_eval { abrir }
puts "  instance_eval { abrir }: #{resultado_eval}"

tesoro = cofre.instance_eval { @tesoro }
puts "  instance_eval { @tesoro }: #{tesoro}"

# Agregar un método singleton (solo para esta instancia)
cofre.instance_eval do
  def destruir
    "Cofre destruido"
  end
end

puts "  cofre.destruir: #{cofre.destruir}"
puts "  Solo cofre tiene el método destruir, otros Cofre no"

# ──────────────────────────────────────────────────────────────────────────────
# 8. Hooks de clase: inherited, included, method_added
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 8. Hooks de clase ──"

class Base
  def self.inherited(subclase)
    puts "  [Hook] #{subclase} hereda de #{name}"
    super
  end
end

module Auditable
  def self.included(clase_base)
    puts "  [Hook] #{name} incluido en #{clase_base}"
  end

  def auditar
    "Auditando #{self.class}"
  end
end

# Al definir estas clases, los hooks se ejecutan automáticamente
class Servicio < Base
  include Auditable
end

class ServicioWeb < Servicio; end

puts "  Servicio.new.auditar: #{Servicio.new.auditar}"

# ──────────────────────────────────────────────────────────────────────────────
# 9. Patrón: DSL simple con metaprogramación
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 9. DSL simple (Domain Specific Language) ──"

class FormBuilder
  attr_reader :campos

  def initialize
    @campos = []
  end

  def self.build(&bloque)
    builder = new
    builder.instance_eval(&bloque)
    builder
  end

  def campo_texto(nombre:, requerido: false)
    @campos << { tipo: :texto, nombre: nombre, requerido: requerido }
  end

  def campo_numero(nombre:, min_val: 0, max_val: 100)
    @campos << { tipo: :numero, nombre: nombre, min: min_val, max: max_val }
  end

  def campo_email(nombre:)
    @campos << { tipo: :email, nombre: nombre, requerido: true }
  end
end

formulario = FormBuilder.build do
  campo_texto nombre: "usuario", requerido: true
  campo_email nombre: "correo"
  campo_numero nombre: "edad", min_val: 18, max_val: 120
end

puts "  Formulario creado con #{formulario.campos.size} campos:"
formulario.campos.each do |campo|
  puts "    - #{campo[:nombre]} (#{campo[:tipo]})"
end

# ──────────────────────────────────────────────────────────────────────────────
# 10. Refinements - Metaprogramación segura y con alcance limitado
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 10. Refinements (alternativa segura a monkey-patching) ──"

# Los refinements permiten modificar clases con alcance lexical limitado,
# evitando los problemas globales del monkey-patching.

module StringExtensions
  refine String do
    def palindromo?
      cleaned = downcase.gsub(/[^a-záéíóúñ]/, "")
      cleaned == cleaned.reverse
    end

    def truncar(longitud:, sufijo: "...")
      return self if length <= longitud
      self[0...(longitud - sufijo.length)] + sufijo
    end
  end
end

# Sin "using", los métodos NO están disponibles
begin
  "anilina".palindromo?
rescue NoMethodError
  puts "  Sin 'using': palindromo? no existe (correcto)"
end

# Con "using", los métodos están disponibles solo en este scope
using StringExtensions

puts '  "anilina".palindromo?: ' + "anilina".palindromo?.to_s
puts '  "hola".palindromo?: ' + "hola".palindromo?.to_s
puts '  "texto largo...".truncar(longitud: 10): ' + "texto largo de ejemplo".truncar(longitud: 10)

# ──────────────────────────────────────────────────────────────────────────────
# 11. Comparación: Formas de extender clases
# ──────────────────────────────────────────────────────────────────────────────
puts "\n── 11. Formas de extender clases (comparación) ──"

puts <<~COMPARACION
  ┌──────────────────────┬───────────┬───────────────────────────────────────┐
  │ Técnica              │ Alcance   │ Uso recomendado                       │
  ├──────────────────────┼───────────┼───────────────────────────────────────┤
  │ Herencia             │ Subclase  │ Relación "es un"                      │
  │ Mixins (include)     │ Clase     │ Compartir comportamiento              │
  │ define_method        │ Clase     │ Generar métodos en lote               │
  │ class_eval           │ Clase     │ Abrir clase desde fuera               │
  │ Monkey-patching      │ Global ⚠️ │ Evitar si es posible                  │
  │ Refinements          │ Lexical ✅│ Extensiones seguras con alcance       │
  │ method_missing       │ Instancia │ Proxy/delegación dinámica             │
  │ Singleton methods    │ Instancia │ Comportamiento único por objeto       │
  └──────────────────────┴───────────┴───────────────────────────────────────┘
COMPARACION

# ──────────────────────────────────────────────────────────────────────────────
# 12. ⚠️  Errores comunes en metaprogramación
# ──────────────────────────────────────────────────────────────────────────────
puts "── 12. Errores comunes ──"

# Error 1: method_missing sin respond_to_missing?
puts "  ❌ method_missing sin respond_to_missing? → respond_to? miente"

# Error 2: method_missing sin llamar a super
puts "  ❌ method_missing sin super → absorbe TODOS los errores silenciosamente"

# Error 3: eval con strings del usuario (inyección de código)
puts "  ❌ eval(user_input) → NUNCA evaluar strings del usuario"
puts "     Usar send/public_send con whitelist en su lugar"

# Error 4: monkey-patching clases core sin cuidado
puts "  ❌ Redefinir String#+ o Array#each → rompe todo el ecosistema"
puts "     Usar Refinements para extensiones seguras"

puts "\n  ✅ Regla de oro: Si puedes resolver el problema sin metaprogramación,"
puts "     probablemente deberías hacerlo sin metaprogramación."

puts "\n✅ Archivo 01_metaprogramacion.rb ejecutado correctamente"
