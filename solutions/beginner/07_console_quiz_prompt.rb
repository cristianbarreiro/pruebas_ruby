# frozen_string_literal: true

require "stringio"

module Solutions
  module Beginner
    # Solicita entradas en consola de forma interactiva e inyectable hasta recibir una opción válida.
    module ConsoleQuizPrompt
      module_function

      def ask_until_valid(prompt:, valid_options:, input: $stdin, output: $stdout, max_attempts: 3)
        validate_prompt_and_attempts!(prompt, max_attempts)
        normalized_options = normalize_options!(valid_options)

        max_attempts.times do
          answer = prompt_once(prompt, input, output)
          return answer if normalized_options.include?(answer)

          output.puts("Opción inválida: #{answer.inspect}. Opciones permitidas: #{normalized_options.join(", ")}")
        end

        raise ArgumentError, "Se agotó el número máximo de intentos (#{max_attempts})"
      end

      def validate_prompt_and_attempts!(prompt, max_attempts)
        valid_prompt = prompt.is_a?(String) && !prompt.strip.empty?
        valid_attempts = max_attempts.is_a?(Integer) && max_attempts.positive?
        raise ArgumentError, "El prompt no puede estar vacío" unless valid_prompt
        raise ArgumentError, "max_attempts debe ser un entero positivo" unless valid_attempts
      end
      private_class_method :validate_prompt_and_attempts!

      def normalize_options!(valid_options)
        raise ArgumentError, "valid_options debe ser un Array no vacío" unless valid_options.is_a?(Array) &&
                                                                               !valid_options.empty?

        options = valid_options.map { |opt| opt.to_s.strip.downcase }
        raise ArgumentError, "Las opciones válidas no pueden estar vacías" if options.any?(&:empty?)

        options
      end
      private_class_method :normalize_options!

      def prompt_once(prompt, input, output)
        output.puts(prompt)
        raw_line = input.gets
        raise ArgumentError, "Se alcanzó el fin de la entrada (EOF) sin respuesta válida" if raw_line.nil?

        raw_line.strip.downcase
      end
      private_class_method :prompt_once
    end
  end
end

if $PROGRAM_NAME == __FILE__
  simulated_in = StringIO.new("quizas\nSI\n")
  simulated_out = StringIO.new
  result = Solutions::Beginner::ConsoleQuizPrompt.ask_until_valid(
    prompt: "¿Deseas continuar? (si/no)",
    valid_options: %w[si no],
    input: simulated_in,
    output: simulated_out
  )
  puts "Respuesta validada: #{result}"
end
