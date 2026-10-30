# frozen_string_literal: true

require_relative "parser"

module LogAnalyzer
  # Procesa archivos de log en streaming usando File.foreach y Enumerator::Lazy
  # sin cargar el archivo completo en memoria.
  class Analyzer
    Report = Data.define(
      :total_lines,
      :valid_entries,
      :malformed_lines,
      :matched_entries,
      :counts_by_level,
      :counts_by_service,
      :repeated_errors,
      :top_messages
    ) do
      alias_method :level_counts, :counts_by_level
      alias_method :service_counts, :counts_by_service

      def to_h
        {
          total_lines: total_lines,
          valid_entries: valid_entries,
          malformed_lines: malformed_lines,
          matched_entries: matched_entries,
          counts_by_level: counts_by_level,
          counts_by_service: counts_by_service,
          repeated_errors: repeated_errors,
          top_messages: top_messages
        }
      end
    end

    attr_reader :file_path, :filters

    def initialize(file_path, **filters)
      raise ArgumentError, "No existe el archivo: #{file_path}" unless File.exist?(file_path.to_s)

      @file_path = file_path.to_s
      @parser = Parser.new
      @filters = normalize_filters(filters)
    end

    # Iterador perezoso de entradas válidas que cumplen los filtros activos.
    def stream_entries
      File.foreach(@file_path, chomp: true)
          .lazy
          .filter_map { |line| @parser.parse_line(line) }
          .select { |entry| matches_filters?(entry) }
    end

    # Analiza el archivo línea por línea con consumo de memoria O(1) por línea.
    def analyze
      counters = initial_counters
      File.foreach(@file_path, chomp: true) do |line|
        process_line(line, counters)
      end
      build_report(counters)
    end

    # Variante ansiosa (carga todo el archivo con File.readlines) para comparar
    # frente a streaming en el benchmark reproducible.
    def analyze_eager
      counters = initial_counters
      File.readlines(@file_path, chomp: true).each do |line|
        process_line(line, counters)
      end
      build_report(counters)
    end

    private

    def normalize_filters(raw)
      {
        level: clean_filter(raw[:level])&.upcase,
        from_date: clean_filter(raw[:from_date]),
        to_date: clean_filter(raw[:to_date]),
        service: clean_filter(raw[:service]),
        query: clean_filter(raw[:query])&.downcase
      }
    end

    def clean_filter(val)
      return nil if val.nil?

      str = val.to_s.strip
      str.empty? ? nil : str
    end

    def initial_counters
      {
        total_lines: 0,
        valid_entries: 0,
        malformed_lines: 0,
        matched_entries: 0,
        levels: Hash.new(0),
        services: Hash.new(0),
        errors: Hash.new(0),
        messages: Hash.new(0)
      }
    end

    def process_line(line, counters)
      counters[:total_lines] += 1
      entry = @parser.parse_line(line)
      if entry.nil?
        counters[:malformed_lines] += 1
        return
      end

      counters[:valid_entries] += 1
      record_match(entry, counters) if matches_filters?(entry)
    end

    def record_match(entry, counters)
      counters[:matched_entries] += 1
      counters[:levels][entry.level] += 1
      counters[:services][entry.service] += 1
      counters[:messages][entry.message] += 1
      counters[:errors][entry.message] += 1 if entry.error?
    end

    def matches_filters?(entry)
      matches_level_and_service?(entry) && matches_date_range?(entry) && matches_query?(entry)
    end

    def matches_level_and_service?(entry)
      level_ok = @filters[:level].nil? || entry.level == @filters[:level]
      service_ok = @filters[:service].nil? || entry.service == @filters[:service]
      level_ok && service_ok
    end

    def matches_date_range?(entry)
      from_ok = @filters[:from_date].nil? || entry.date >= @filters[:from_date]
      to_ok = @filters[:to_date].nil? || entry.date <= @filters[:to_date]
      from_ok && to_ok
    end

    def matches_query?(entry)
      return true if @filters[:query].nil?

      entry.message.downcase.include?(@filters[:query])
    end

    def build_report(counters)
      Report.new(
        total_lines: counters[:total_lines],
        valid_entries: counters[:valid_entries],
        malformed_lines: counters[:malformed_lines],
        matched_entries: counters[:matched_entries],
        counts_by_level: sort_desc(counters[:levels]),
        counts_by_service: sort_desc(counters[:services]),
        repeated_errors: select_repeated(counters[:errors]),
        top_messages: sort_desc(counters[:messages]).first(5).to_h
      )
    end

    def sort_desc(counts)
      counts.sort_by { |_key, cnt| -cnt }.to_h
    end

    def select_repeated(error_counts)
      sort_desc(error_counts.select { |_msg, cnt| cnt >= 2 })
    end
  end
end
