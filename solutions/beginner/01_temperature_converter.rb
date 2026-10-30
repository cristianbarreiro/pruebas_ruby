# frozen_string_literal: true

module Solutions
  module Beginner
    # Conversor de temperaturas entre Celsius, Fahrenheit y Kelvin usando Kelvin como escala pivote.
    module TemperatureConverter
      SCALES = %i[celsius fahrenheit kelvin].freeze
      ABSOLUTE_ZERO_OFFSET = 273.15
      FLOAT_TOLERANCE = -1e-9

      module_function

      def convert(value, from:, to:)
        validate_arguments!(value, from, to)
        kelvin = to_kelvin(value.to_f, from)
        raise ArgumentError, "La temperatura es inferior al cero absoluto (0 K)" if kelvin < FLOAT_TOLERANCE

        from_kelvin([kelvin, 0.0].max, to).round(2)
      end

      def validate_arguments!(value, from_scale, to_scale)
        raise ArgumentError, "El valor debe ser numérico" unless value.is_a?(Numeric)
        raise ArgumentError, "Escala de origen desconocida: #{from_scale.inspect}" unless SCALES.include?(from_scale)
        raise ArgumentError, "Escala de destino desconocida: #{to_scale.inspect}" unless SCALES.include?(to_scale)
      end
      private_class_method :validate_arguments!

      def to_kelvin(val, scale)
        case scale
        when :kelvin then val
        when :celsius then val + ABSOLUTE_ZERO_OFFSET
        when :fahrenheit then ((val - 32.0) * 5.0 / 9.0) + ABSOLUTE_ZERO_OFFSET
        end
      end
      private_class_method :to_kelvin

      def from_kelvin(kelvin, scale)
        case scale
        when :kelvin then kelvin
        when :celsius then kelvin - ABSOLUTE_ZERO_OFFSET
        when :fahrenheit then ((kelvin - ABSOLUTE_ZERO_OFFSET) * 9.0 / 5.0) + 32.0
        end
      end
      private_class_method :from_kelvin
    end
  end
end

if $PROGRAM_NAME == __FILE__
  converter = Solutions::Beginner::TemperatureConverter
  puts "0 °C -> °F: #{converter.convert(0, from: :celsius, to: :fahrenheit)}"
  puts "100 °C -> K: #{converter.convert(100, from: :celsius, to: :kelvin)}"
  puts "98.6 °F -> °C: #{converter.convert(98.6, from: :fahrenheit, to: :celsius)}"
end
