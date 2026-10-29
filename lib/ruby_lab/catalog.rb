# frozen_string_literal: true

module RubyLab
  # Descubre ejemplos y ejercicios leyendo el sistema de archivos.
  #
  # Decisión de diseño: el catálogo no mantiene una lista codificada a mano.
  # Al añadir un archivo que siga las convenciones, aparece automáticamente:
  #
  # * Ejemplos: examples/NN_modulo/NN_tema.rb con una línea "# = Título".
  # * Ejercicios: exercises/<nivel>/NN_nombre.md cuyo primer encabezado es "# Título".
  class Catalog
    Entry = Data.define(:id, :group, :title, :path)

    LEVELS = %w[beginner intermediate advanced].freeze
    RUBY_TITLE = /\A#\s*=\s*(?<title>.+?)\s*\z/
    MARKDOWN_TITLE = /\A#\s+(?<title>.+?)\s*\z/

    def initialize(root: RubyLab.root)
      @root = root
    end

    # Directorios de módulos de ejemplos, ordenados (01_fundamentos, ...).
    def modules
      Dir.children(examples_dir)
         .select { |name| File.directory?(File.join(examples_dir, name)) }
         .sort
    end

    # Todos los ejemplos o solo los de los módulos cuyo nombre empieza por +prefix+.
    def examples(prefix = nil)
      selected = prefix ? modules.select { |name| name.start_with?(prefix) } : modules
      selected.flat_map { |module_name| example_entries(module_name) }
    end

    # Busca un ejemplo por identificador ("01/02") o por ruta relativa.
    def find_example(query)
      normalized = query.to_s.tr("\\", "/")
      examples.find { |entry| entry.id == normalized || entry.path == normalized }
    end

    def exercises(level = nil)
      levels = level ? [validate_level(level)] : LEVELS
      levels.flat_map { |name| exercise_entries(name) }
    end

    def absolute_path(entry)
      File.join(@root, entry.path)
    end

    private

    def examples_dir
      File.join(@root, "examples")
    end

    def example_entries(module_name)
      Dir.glob(File.join(examples_dir, module_name, "*.rb")).map do |path|
        Entry.new(
          id: "#{module_name[0, 2]}/#{File.basename(path)[0, 2]}",
          group: module_name,
          title: read_title(path, RUBY_TITLE),
          path: relative(path)
        )
      end
    end

    def exercise_entries(level)
      Dir.glob(File.join(@root, "exercises", level, "*.md")).map do |path|
        Entry.new(
          id: "#{level}/#{File.basename(path, ".md")}",
          group: level,
          title: read_title(path, MARKDOWN_TITLE),
          path: relative(path)
        )
      end
    end

    # Lee el archivo de forma perezosa: se detiene en la primera coincidencia.
    def read_title(path, pattern)
      File.foreach(path, chomp: true)
          .lazy
          .filter_map { |line| pattern.match(line)&.[](:title) }
          .first || File.basename(path)
    end

    def relative(path)
      path.delete_prefix("#{@root}/")
    end

    def validate_level(level)
      return level if LEVELS.include?(level)

      raise ArgumentError, "Nivel desconocido: #{level}. Usa uno de: #{LEVELS.join(", ")}"
    end
  end
end
