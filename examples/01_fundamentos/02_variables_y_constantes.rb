# frozen_string_literal: true

# = Variables locales, de instancia, de clase y constantes
#
# Ejecución: ruby examples/01_fundamentos/02_variables_y_constantes.rb
#
# El prefijo de una variable determina su alcance:
#   nombre    -> local: visible en el bloque/método/archivo donde se define
#   @nombre   -> de instancia: pertenece a un objeto concreto
#   @@nombre  -> de clase: compartida por la clase y TODAS sus subclases
#   NOMBRE    -> constante: empieza por mayúscula; reasignarla produce un warning
#   $nombre   -> global: visible en todo el programa (evítala)

puts "== Variables locales =="
city = "Valparaíso"
puts "city = #{city}"
# Las variables locales no son visibles dentro de `def` (def abre un nuevo ámbito).
def show_local
  defined?(city) ? "visible" : "city no está definida aquí"
end
puts show_local

puts "\n== Variables de instancia =="
class Account
  def initialize(owner)
    @owner = owner # existe mientras exista el objeto
    @balance = 0
  end

  def deposit(amount)
    @balance += amount
    self
  end

  def summary
    "#{@owner}: #{@balance}"
  end
end

ana = Account.new("Ana").deposit(100)
luis = Account.new("Luis").deposit(30)
puts ana.summary
puts luis.summary # cada objeto tiene su propio @balance

puts "\n== Variables de instancia de clase (preferibles a @@) =="
class Counter # rubocop:disable Style/OneClassPerFile -- ejemplo didáctico: varias clases en un archivo
  @instances = 0 # pertenece al objeto Counter (la clase), no a sus instancias

  class << self
    attr_reader :instances

    def track
      @instances += 1
    end
  end

  def initialize
    self.class.track
  end
end
3.times { Counter.new }
puts "Counter.instances = #{Counter.instances}"

puts "\n== Constantes =="
TAX_RATE = 0.19
COUNTRIES = %w[Chile Perú Uruguay].freeze # congela también el contenedor
puts "TAX_RATE = #{TAX_RATE}"
puts "COUNTRIES congelado? #{COUNTRIES.frozen?}"

puts "\n== Error común: @@variables compartidas con subclases =="
# rubocop:disable Style/ClassVars, Style/OneClassPerFile -- se muestra a propósito el problema
class Base
  @@registry = []

  def self.register(item) = @@registry << item
  def self.registry = @@registry
end

class Child < Base; end

Child.register(:child_item)
# La subclase modificó el MISMO array que la clase padre:
puts "Base.registry = #{Base.registry.inspect}"
# rubocop:enable Style/ClassVars, Style/OneClassPerFile
puts "Solución: usa variables de instancia de clase (@instances en Counter)."

puts "\n== Error común: variables globales =="
# Una global puede modificarse desde cualquier parte, lo que dificulta razonar
# sobre el programa y probarlo. Pasa los valores como argumentos o inyéctalos.
puts "Ruby predefine algunas globales útiles: $stdout, $PROGRAM_NAME, $LOAD_PATH"
