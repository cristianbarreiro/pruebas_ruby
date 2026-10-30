# frozen_string_literal: true

# = Refactorización de generador de reportes legado con polimorfismo

require "csv"
require "json"

module Solutions
  module Intermediate
    module LegacyReportRefactoring
      MetricEntry = Data.define(:service, :latency_ms, :success)

      MetricsSummary = Data.define(
        :title,
        :total_requests,
        :average_latency_ms,
        :success_rate_percent
      ) do
        def self.from_entries(title:, entries:)
          total = entries.size
          return new(title: title, total_requests: 0, average_latency_ms: 0.0, success_rate_percent: 0.0) if total.zero?

          avg_latency = (entries.sum(&:latency_ms).to_f / total).round(2)
          success_count = entries.count(&:success)
          success_rate = (success_count * 100.0 / total).round(2)
          new(
            title: title, total_requests: total,
            average_latency_ms: avg_latency, success_rate_percent: success_rate
          )
        end
      end

      class TextFormatter
        def format(summary)
          "Report: #{summary.title} | Requests: #{summary.total_requests} | " \
            "Avg Latency: #{summary.average_latency_ms}ms | Success: #{summary.success_rate_percent}%"
        end
      end

      class JsonFormatter
        def format(summary)
          JSON.generate(
            title: summary.title,
            total_requests: summary.total_requests,
            average_latency_ms: summary.average_latency_ms,
            success_rate_percent: summary.success_rate_percent
          )
        end
      end

      class CsvFormatter
        HEADERS = %w[title total_requests average_latency_ms success_rate_percent].freeze

        def format(summary)
          CSV.generate do |csv|
            csv << HEADERS
            csv << [
              summary.title,
              summary.total_requests,
              summary.average_latency_ms,
              summary.success_rate_percent
            ]
          end
        end
      end

      class ReportGenerator
        FORMATTERS = {
          text: TextFormatter,
          json: JsonFormatter,
          csv: CsvFormatter
        }.freeze

        def self.for_format(format_symbol)
          formatter_class = FORMATTERS.fetch(format_symbol.to_sym) do
            raise ArgumentError, "Unsupported report format: #{format_symbol}"
          end
          new(formatter: formatter_class.new)
        end

        def initialize(formatter: TextFormatter.new)
          @formatter = formatter
        end

        def generate(title:, entries:)
          summary = MetricsSummary.from_entries(title: title, entries: entries)
          @formatter.format(summary)
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mod = Solutions::Intermediate::LegacyReportRefactoring
  entries = [
    mod::MetricEntry.new(service: "auth", latency_ms: 120, success: true),
    mod::MetricEntry.new(service: "auth", latency_ms: 180, success: false)
  ]
  puts mod::ReportGenerator.for_format(:text).generate(title: "Auth SLA", entries: entries)
end
