# frozen_string_literal: true

module Solutions
  module Beginner
    # Validador declarativo de contraseñas que acumula todos los errores encontrados.
    module PasswordValidator
      Rule = Data.define(:message, :matcher)

      RULES = [
        Rule.new("Debe tener al menos 8 caracteres", ->(pwd) { pwd.length >= 8 }),
        Rule.new("Debe incluir al menos una letra mayúscula", ->(pwd) { pwd.match?(/[A-ZÁÉÍÓÚÜÑ]/) }),
        Rule.new("Debe incluir al menos una letra minúscula", ->(pwd) { pwd.match?(/[a-záéíóúüñ]/) }),
        Rule.new("Debe incluir al menos un dígito", ->(pwd) { pwd.match?(/\d/) }),
        Rule.new("Debe incluir al menos un símbolo", ->(pwd) { pwd.match?(/[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9\s]/) }),
        Rule.new("No debe contener espacios en blanco", ->(pwd) { !pwd.match?(/\s/) })
      ].freeze

      module_function

      def validate(password)
        raise ArgumentError, "La contraseña debe ser un String" unless password.is_a?(String)

        errors = RULES.filter_map do |rule|
          rule.message unless rule.matcher.call(password)
        end

        { valid: errors.empty?, errors: errors }
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  validator = Solutions::Beginner::PasswordValidator
  puts validator.validate("Segura#2026").inspect
  puts validator.validate("corta").inspect
end
