# frozen_string_literal: true

module Solutions
  module Beginner
    # Calcula medidas estadísticas descriptivas de tendencia central y dispersión.
    module CollectionStatistics
      module_function

      def analyze(numbers)
        validate_numbers!(numbers)
        sorted = numbers.sort
        total = sorted.sum
        min_val = sorted.first
        max_val = sorted.last

        {
          count: sorted.size,
          sum: total,
          mean: (total.to_f / sorted.size).round(2),
          median: calculate_median(sorted),
          modes: calculate_modes(sorted),
          min: min_val,
          max: max_val,
          range: max_val - min_val
        }
      end

      def validate_numbers!(numbers)
        raise ArgumentError, "La colección debe ser un Array no vacío" unless numbers.is_a?(Array) && !numbers.empty?
        return if numbers.all? { |num| valid_number?(num) }

        raise ArgumentError, "Todos los elementos deben ser valores numéricos finitos"
      end
      private_class_method :validate_numbers!

      def valid_number?(num)
        return false unless num.is_a?(Numeric)
        return num.finite? if num.respond_to?(:finite?)

        true
      end
      private_class_method :valid_number?

      def calculate_median(sorted)
        mid = sorted.size / 2
        if sorted.size.odd?
          sorted[mid].to_f.round(2)
        else
          ((sorted[mid - 1] + sorted[mid]) / 2.0).round(2)
        end
      end
      private_class_method :calculate_median

      def calculate_modes(sorted)
        frequencies = sorted.tally
        max_freq = frequencies.values.max
        frequencies.filter_map { |val, freq| val if freq == max_freq }
      end
      private_class_method :calculate_modes
    end
  end
end

if $PROGRAM_NAME == __FILE__
  sample = [10, 20, 20, 30, 40]
  puts Solutions::Beginner::CollectionStatistics.analyze(sample).inspect
end
