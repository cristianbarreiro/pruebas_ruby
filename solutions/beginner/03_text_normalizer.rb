# frozen_string_literal: true

module Solutions
  module Beginner
    # Normalizador de texto en español para slugs, conteo de palabras y títulos.
    module TextNormalizer
      ACCENTED_CHARS = "ÁÉÍÓÚÜÑáéíóúüñ"
      ASCII_CHARS = "AEIOUUNaeiouun"
      MINOR_WORDS = %w[de del la las el los en y o a con por para sin un una].freeze
      SPANISH_UPPER = { "á" => "Á", "é" => "É", "í" => "Í", "ó" => "Ó", "ú" => "Ú", "ü" => "Ü", "ñ" => "Ñ" }.freeze
      SPANISH_LOWER = SPANISH_UPPER.invert.freeze

      module_function

      def slugify(text)
        ensure_string!(text)
        downcase_spanish(text)
          .tr(ACCENTED_CHARS, ASCII_CHARS)
          .gsub(/[^a-z0-9]+/, "-")
          .gsub(/\A-+|-+\z/, "")
      end

      def word_count(text)
        ensure_string!(text)
        downcase_spanish(text).scan(/[a-záéíóúüñ0-9]+/).tally
      end

      def titleize(text)
        ensure_string!(text)
        words = downcase_spanish(text).split
        words.each_with_index.map do |word, idx|
          idx.zero? || !MINOR_WORDS.include?(word) ? capitalize_spanish(word) : word
        end.join(" ")
      end

      def ensure_string!(text)
        raise ArgumentError, "El texto debe ser un String" unless text.is_a?(String)
      end
      private_class_method :ensure_string!

      def downcase_spanish(text)
        text.downcase.gsub(/[ÁÉÍÓÚÜÑ]/, SPANISH_LOWER)
      end
      private_class_method :downcase_spanish

      def capitalize_spanish(word)
        return "" if word.empty?

        first = word[0]
        upper_first = SPANISH_UPPER.fetch(first, first.upcase)
        "#{upper_first}#{word[1..]}"
      end
      private_class_method :capitalize_spanish
    end
  end
end

if $PROGRAM_NAME == __FILE__
  normalizer = Solutions::Beginner::TextNormalizer
  puts normalizer.slugify("¡Programación en Ruby: Guía Rápida 2026!")
  puts normalizer.word_count("Ruby es simple, Ruby es expresivo.").inspect
  puts normalizer.titleize("el arte de programar en ruby y no morir en el intento")
end
