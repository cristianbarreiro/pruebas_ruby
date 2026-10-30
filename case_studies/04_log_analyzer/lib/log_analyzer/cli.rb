# frozen_string_literal: true

require "optparse"
require_relative "analyzer"
require_relative "reporter"

module LogAnalyzer
  # Interfaz de línea de comandos para analizar archivos de log y exportar reportes.
  class CLI
    def self.run(argv = ARGV, stdout: $stdout, stderr: $stderr)
      new(argv, stdout: stdout, stderr: stderr).run
    end

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv.dup
      @stdout = stdout
      @stderr = stderr
      @options = { format: "text" }
    end

    def run
      return 0 if parse_options! == :help

      file_path = @argv.shift
      return missing_file_error if file_path.nil?

      report = Analyzer.new(file_path, **filter_options).analyze
      emit_output(report)
      0
    rescue OptionParser::ParseError, ArgumentError => e
      @stderr.puts "Error: #{e.message}"
      1
    end

    private

    def parse_options!
      parser = build_option_parser
      parser.parse!(@argv)
      :help if @options[:help]
    end

    def build_option_parser
      OptionParser.new do |opts|
        opts.banner = "Uso: log-analyzer [opciones] <archivo.log>"
        register_filter_options(opts)
        register_output_options(opts)
      end
    end

    def register_filter_options(opts)
      opts.on("-l", "--level LEVEL", "Filtra por severidad (DEBUG, INFO, WARN, ERROR, FATAL)") do |val|
        @options[:level] = val
      end
      opts.on("-f", "--from DATE", "Fecha inicial YYYY-MM-DD") { |val| @options[:from_date] = val }
      opts.on("-t", "--to DATE", "Fecha final YYYY-MM-DD") { |val| @options[:to_date] = val }
      opts.on("-s", "--service NAME", "Filtra por servicio") { |val| @options[:service] = val }
      opts.on("-q", "--query TEXT", "Filtra por texto en el mensaje") { |val| @options[:query] = val }
    end

    def register_output_options(opts)
      opts.on("--format FORMAT", %w[text json csv], "Formato: text, json, csv") do |val|
        @options[:format] = val
      end
      opts.on("-o", "--output FILE", "Ruta de exportación opcional") { |val| @options[:output] = val }
      opts.on("-h", "--help", "Muestra esta ayuda") do
        @stdout.puts opts
        @options[:help] = true
      end
    end

    def filter_options
      @options.slice(:level, :from_date, :to_date, :service, :query)
    end

    def emit_output(report)
      rendered = render_report(report)
      if @options[:output]
        File.write(@options[:output], rendered, encoding: "UTF-8")
      else
        @stdout.puts rendered
      end
    end

    def render_report(report)
      case @options[:format]
      when "json" then Reporter.to_json(report)
      when "csv" then Reporter.to_csv(report)
      else Reporter.to_text(report)
      end
    end

    def missing_file_error
      @stderr.puts "Error: Debe indicar la ruta de un archivo de log."
      1
    end
  end
end
