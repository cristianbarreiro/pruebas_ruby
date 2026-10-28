# frozen_string_literal: true

require "rbconfig"

module RubyLab
  # Interfaz de línea de comandos para navegar el laboratorio.
  #
  # Las dependencias de E/S (salida estándar, error y ejecución de procesos) se
  # inyectan para poder probar la CLI sin abrir procesos ni capturar $stdout.
  class CLI
    USAGE = <<~TEXT
      Uso: ruby-lab <comando> [argumentos]

      Comandos:
        list [PREFIJO]      Lista los ejemplos (p. ej. "list 05" filtra un módulo)
        run ID              Ejecuta un ejemplo por identificador (p. ej. "run 01/02")
        exercises [NIVEL]   Lista los ejercicios: beginner, intermediate o advanced
        version             Muestra la versión del laboratorio
        help                Muestra esta ayuda
    TEXT

    def initialize(out: $stdout, err: $stderr, catalog: Catalog.new, runner: nil)
      @out = out
      @err = err
      @catalog = catalog
      @runner = runner || ->(path) { system(RbConfig.ruby, path) }
    end

    # Devuelve un código de salida (0 = éxito) en lugar de llamar a +exit+,
    # lo que permite probar el método directamente.
    def call(argv)
      command, *args = argv
      dispatch(command, args)
    rescue ArgumentError => e
      fail_with(e.message)
    end

    private

    def dispatch(command, args)
      case command
      when "list" then list(args.first)
      when "run" then run(args.first)
      when "exercises" then exercises(args.first)
      when "version", "--version", "-v" then print_line(VERSION)
      when nil, "help", "--help", "-h" then print_line(USAGE)
      else fail_with("Comando desconocido: #{command}\n\n#{USAGE}")
      end
    end

    def list(prefix)
      entries = @catalog.examples(prefix)
      return fail_with("No hay ejemplos para el prefijo #{prefix.inspect}") if entries.empty?

      entries.group_by(&:group).each do |group, group_entries|
        @out.puts group
        group_entries.each { |entry| @out.puts format("  %-6<id>s %<title>s", id: entry.id, title: entry.title) }
      end
      0
    end

    def run(id)
      return fail_with("Indica el identificador del ejemplo. Ejemplo: ruby-lab run 01/01") if id.nil?

      entry = @catalog.find_example(id)
      return fail_with("No existe el ejemplo #{id.inspect}. Usa 'ruby-lab list'.") unless entry

      @runner.call(@catalog.absolute_path(entry)) ? 0 : 1
    end

    def exercises(level)
      @catalog.exercises(level).each do |entry|
        @out.puts format("%-40<id>s %<title>s", id: entry.id, title: entry.title)
      end
      0
    end

    def print_line(text)
      @out.puts(text)
      0
    end

    def fail_with(message)
      @err.puts(message)
      1
    end
  end
end
