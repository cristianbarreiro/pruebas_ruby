# frozen_string_literal: true

module Solutions
  module Beginner
    # Generador de secuencias numéricas parametrizadas (FizzBuzz, Collatz y suma de múltiplos).
    module NumberSeriesGenerator
      DEFAULT_FIZZ_BUZZ = { 3 => "Fizz", 5 => "Buzz" }.freeze

      module_function

      def fizz_buzz(limit, rules: DEFAULT_FIZZ_BUZZ)
        ensure_positive_integer!(limit, "limit")
        validate_rules!(rules)

        (1..limit).map { |num| format_fizz_buzz(num, rules) }
      end

      def collatz_sequence(start)
        ensure_positive_integer!(start, "start")

        sequence = [start]
        current = start
        while current > 1
          current = current.even? ? current / 2 : (current * 3) + 1
          sequence << current
        end
        sequence
      end

      def sum_of_multiples(limit, factors: [3, 5])
        ensure_positive_integer!(limit, "limit")
        validate_factors!(factors)

        (1..limit).select do |num|
          factors.any? { |factor| (num % factor).zero? }
        end.sum
      end

      def ensure_positive_integer!(val, name)
        return if val.is_a?(Integer) && val.positive?

        raise ArgumentError, "#{name} debe ser un entero positivo"
      end
      private_class_method :ensure_positive_integer!

      def validate_rules!(rules)
        raise ArgumentError, "rules debe ser un Hash no vacío" unless rules.is_a?(Hash) && !rules.empty?

        rules.each do |divisor, label|
          ensure_positive_integer!(divisor, "divisor")
          raise ArgumentError, "La etiqueta debe ser un String no vacío" unless label.is_a?(String) && !label.empty?
        end
      end
      private_class_method :validate_rules!

      def validate_factors!(factors)
        raise ArgumentError, "factors debe ser un Array no vacío" unless factors.is_a?(Array) && !factors.empty?

        factors.each { |factor| ensure_positive_integer!(factor, "factor") }
      end
      private_class_method :validate_factors!

      def format_fizz_buzz(num, rules)
        label = rules.each_with_object(+"") do |(divisor, word), acc|
          acc << word if (num % divisor).zero?
        end
        label.empty? ? num.to_s : label
      end
      private_class_method :format_fizz_buzz
    end
  end
end

if $PROGRAM_NAME == __FILE__
  gen = Solutions::Beginner::NumberSeriesGenerator
  puts "FizzBuzz(15): #{gen.fizz_buzz(15).join(", ")}"
  puts "Collatz(6): #{gen.collatz_sequence(6).inspect}"
  puts "Suma múltiplos(10): #{gen.sum_of_multiples(10)}"
end
