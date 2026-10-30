# frozen_string_literal: true

require "csv"
require "fileutils"
require "json"

module LogAnalyzer
  # Exporta los resultados de un análisis de logs a texto legible, JSON o CSV.
  class Reporter
    CSV_HEADERS = %w[category key count].freeze

    def self.to_json(report)
      JSON.pretty_generate(report.to_h)
    end

    def self.to_csv(report)
      CSV.generate(headers: CSV_HEADERS, write_headers: true) do |csv|
        append_summary_rows(csv, report)
        append_group_rows(csv, "level", report.counts_by_level)
        append_group_rows(csv, "service", report.counts_by_service)
        append_group_rows(csv, "repeated_error", report.repeated_errors)
      end
    end

    def self.to_text(report)
      lines = [
        "=== Resumen de análisis de logs ===",
        "Líneas totales:       #{report.total_lines}",
        "Entradas válidas:     #{report.valid_entries}",
        "Líneas malformadas:   #{report.malformed_lines}",
        "Entradas filtradas:   #{report.matched_entries}"
      ]
      lines.concat(format_section("Conteo por nivel:", report.counts_by_level))
      lines.concat(format_section("Errores repetidos (>= 2):", report.repeated_errors))
      lines.join("\n")
    end

    def self.write_json(report, output_path)
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, to_json(report), encoding: "UTF-8")
    end

    def self.write_csv(report, output_path)
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, to_csv(report), encoding: "UTF-8")
    end

    class << self
      private

      def append_summary_rows(csv, report)
        csv << ["summary", "total_lines", report.total_lines]
        csv << ["summary", "valid_entries", report.valid_entries]
        csv << ["summary", "malformed_lines", report.malformed_lines]
        csv << ["summary", "matched_entries", report.matched_entries]
      end

      def append_group_rows(csv, category, mapping)
        mapping.each do |key, count|
          csv << [category, key, count]
        end
      end

      def format_section(title, mapping)
        return ["\n#{title}", "  (ninguno)"] if mapping.empty?

        rows = mapping.map { |key, cnt| "  - #{key}: #{cnt}" }
        ["\n#{title}", *rows]
      end
    end
  end
end
