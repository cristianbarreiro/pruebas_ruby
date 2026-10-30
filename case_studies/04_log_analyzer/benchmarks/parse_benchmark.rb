# frozen_string_literal: true

require "benchmark"
require "tmpdir"
require_relative "../lib/log_analyzer"

# Genera archivos sintéticos de log en un directorio temporal y compara el
# análisis en streaming (File.foreach) frente al análisis ansioso (File.readlines).
module LogBenchmarkRunner
  SERVICES = %w[api-gateway auth-service order-worker payment-gateway].freeze
  LEVELS = %w[INFO INFO INFO WARN ERROR DEBUG].freeze
  MESSAGES = [
    "Solicitud HTTP procesada correctamente",
    "Timeout conectando a base de datos primaria",
    "Token JWT expirado o firma inválida",
    "Latencia elevada en llamada remota"
  ].freeze

  module_function

  def generate_log_file(path, line_count)
    File.open(path, "w", encoding: "UTF-8") do |file|
      line_count.times do |idx|
        file.puts(sample_line(idx))
      end
    end
  end

  def sample_line(idx)
    return "LINEA_MALFORMADA_SINTETICA_#{idx}" if (idx % 97).zero?

    level = LEVELS[idx % LEVELS.size]
    service = SERVICES[idx % SERVICES.size]
    message = MESSAGES[idx % MESSAGES.size]
    hour = format("%02d", idx % 24)
    minute = format("%02d", idx % 60)
    "2026-03-15 #{hour}:#{minute}:10 [#{level}] #{service} - #{message}"
  end

  def run
    puts "=== Benchmark de LogAnalyzer (Streaming vs Eager) ==="
    Dir.mktmpdir("log_analyzer_bench") do |dir|
      [1_000, 10_000].each do |size|
        run_for_size(dir, size)
      end
    end
  end

  def run_for_size(dir, size)
    file_path = File.join(dir, "synthetic_#{size}.log")
    generate_log_file(file_path, size)
    analyzer = LogAnalyzer::Analyzer.new(file_path, level: "ERROR")

    puts "\nArchivo sintético de #{size} líneas:"
    Benchmark.bm(22) do |bench|
      bench.report("streaming (foreach):") { analyzer.analyze }
      bench.report("eager (readlines):") { analyzer.analyze_eager }
    end
  end
end

LogBenchmarkRunner.run if $PROGRAM_NAME == __FILE__
