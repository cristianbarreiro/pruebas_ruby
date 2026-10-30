# frozen_string_literal: true

require "stringio"

module Solutions
  module Advanced
    module StreamingLogAggregator
      LogEntry = Data.define(:timestamp, :level, :service, :message)

      LOG_PATTERN = /\A\[(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] (?<level>DEBUG|INFO|WARN|ERROR|FATAL) (?<service>[a-zA-Z0-9_-]+): (?<message>.+)\z/ # rubocop:disable Layout/LineLength

      class LogAggregator
        def initialize(max_samples: 5)
          @max_samples = max_samples
        end

        def self.parse_line(raw_line)
          match = LOG_PATTERN.match(raw_line.to_s.chomp)
          return nil unless match

          LogEntry.new(
            timestamp: match[:timestamp],
            level: match[:level],
            service: match[:service],
            message: match[:message].strip
          )
        end

        def lazy_entries(source)
          lazy_lines(source).filter_map { |line, _num| self.class.parse_line(line) }
        end

        def aggregate(source, level_filter: nil, service_filter: nil)
          state = initial_state
          lazy_lines(source).each do |raw_line, line_num|
            next if raw_line.strip.empty?

            process_line(state, raw_line, line_num, level_filter, service_filter)
          end
          state
        end

        def aggregate_file(file_path, **filters)
          File.open(file_path, "r") { |file| aggregate(file, **filters) }
        end

        private

        def lazy_lines(source)
          enumerator = source.respond_to?(:each_line) ? source.each_line : source.each
          enumerator.lazy.with_index(1).map { |line, idx| [line.to_s.chomp, idx] }
        end

        def initial_state
          {
            total_lines: 0,
            valid_lines: 0,
            malformed_lines: 0,
            malformed_samples: [],
            by_level: Hash.new(0),
            by_service: Hash.new(0)
          }
        end

        def process_line(state, raw_line, line_num, level_filter, service_filter)
          state[:total_lines] += 1
          entry = self.class.parse_line(raw_line)
          return record_malformed(state, raw_line, line_num) unless entry
          return unless matches_filters?(entry, level_filter, service_filter)

          state[:valid_lines] += 1
          state[:by_level][entry.level] += 1
          state[:by_service][entry.service] += 1
        end

        def record_malformed(state, raw_line, line_num)
          state[:malformed_lines] += 1
          return if state[:malformed_samples].size >= @max_samples

          state[:malformed_samples] << { line_number: line_num, raw: raw_line }
        end

        def matches_filters?(entry, level_filter, service_filter)
          level_ok = level_filter.nil? || entry.level == level_filter.to_s.upcase
          service_ok = service_filter.nil? || entry.service == service_filter.to_s
          level_ok && service_ok
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  sample_stream = StringIO.new(<<~LOGS)
    [2026-05-10 10:00:01] INFO auth: Sesión iniciada
    línea corrupta sin formato válido
    [2026-05-10 10:00:04] ERROR billing: Fallo al cobrar tarjeta
    [2026-05-10 10:00:09] INFO auth: Token renovado
  LOGS

  aggregator = Solutions::Advanced::StreamingLogAggregator::LogAggregator.new
  summary = aggregator.aggregate(sample_stream)
  puts "Resumen de agregación en streaming:"
  p summary
end
