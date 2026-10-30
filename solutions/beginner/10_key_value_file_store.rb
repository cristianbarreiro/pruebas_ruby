# frozen_string_literal: true

require "tmpdir"

module Solutions
  module Beginner
    # Persistencia simple de pares clave=valor en archivos de texto con soporte de comentarios.
    module KeyValueFileStore
      module_function

      def load_file(path)
        ensure_existing_file!(path)

        store = {}
        File.foreach(path, chomp: true).with_index(1) do |line, line_num|
          stripped = line.strip
          next if stripped.empty? || stripped.start_with?("#")

          key, val = parse_line(stripped, line_num)
          store[key] = val
        end
        store
      end

      def save_file(path, hash)
        validate_save_args!(path, hash)

        lines = hash.map do |raw_key, raw_val|
          format_pair(raw_key, raw_val)
        end

        File.write(path, lines.empty? ? "" : "#{lines.join("\n")}\n")
        hash.size
      end

      def ensure_existing_file!(path)
        valid_path = (path.is_a?(String) || path.respond_to?(:to_path)) && File.file?(path)
        raise ArgumentError, "El archivo no existe: #{path.inspect}" unless valid_path
      end
      private_class_method :ensure_existing_file!

      def parse_line(line, line_num)
        raise ArgumentError, "Línea #{line_num} mal formada (falta '='): #{line}" unless line.include?("=")

        raw_key, raw_val = line.split("=", 2)
        key = raw_key.strip
        raise ArgumentError, "Línea #{line_num} tiene una clave vacía" if key.empty?

        [key, raw_val.to_s.strip]
      end
      private_class_method :parse_line

      def validate_save_args!(path, hash)
        valid_path = (path.is_a?(String) || path.respond_to?(:to_path)) && !path.to_s.strip.empty?
        raise ArgumentError, "Ruta de archivo inválida" unless valid_path
        raise ArgumentError, "Los datos deben ser un Hash" unless hash.is_a?(Hash)
      end
      private_class_method :validate_save_args!

      def format_pair(raw_key, raw_val)
        key = raw_key.to_s.strip
        val = raw_val.to_s.strip
        if key.empty? || key.include?("=") || key.include?("\n") || val.include?("\n")
          raise ArgumentError, "Clave o valor inválido para serializar: #{raw_key.inspect}"
        end

        "#{key}=#{val}"
      end
      private_class_method :format_pair
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Dir.mktmpdir do |dir|
    sample_file = File.join(dir, "app.env")
    Solutions::Beginner::KeyValueFileStore.save_file(sample_file, { "HOST" => "localhost", "PORT" => "8080" })
    puts Solutions::Beginner::KeyValueFileStore.load_file(sample_file).inspect
  end
end
