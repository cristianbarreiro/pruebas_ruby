# frozen_string_literal: true

module LogAnalyzer
  LEVELS = %w[DEBUG INFO WARN ERROR FATAL].freeze
  ERROR_LEVELS = %w[ERROR FATAL].freeze

  # Representa una entrada de log validada e inmutable.
  #
  # Se utiliza Data.define para garantizar inmutabilidad por valor sin
  # sobrecarga de objetos mutables durante el procesamiento de miles de líneas.
  LogEntry = Data.define(:timestamp, :level, :service, :message) do
    def date
      timestamp[0, 10]
    end

    def error?
      ERROR_LEVELS.include?(level)
    end

    def severity_rank
      LEVELS.index(level) || -1
    end

    def to_h
      {
        timestamp: timestamp,
        level: level,
        service: service,
        message: message
      }
    end
  end
end
