# frozen_string_literal: true

require_relative "log_entry"

module LogAnalyzer
  # Analiza líneas de log individuales con formato estructurado:
  #   YYYY-MM-DD HH:MM:SS [LEVEL] service - message
  #
  # Ejemplo válido:
  #   2026-03-15 08:12:01 [ERROR] auth-service - Token JWT expirado
  #
  # Si una línea está vacía o no cumple exactamente la estructura esperada,
  # devuelve +nil+ en lugar de lanzar una excepción para permitir que el
  # flujo en streaming continúe procesando el resto del archivo.
  class Parser
    LOG_PATTERN = /\A
      (?<timestamp>\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])\s(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d)\s+
      \[(?<level>DEBUG|INFO|WARN|ERROR|FATAL)\]\s+
      (?<service>[a-zA-Z0-9_.-]+)\s+-\s+
      (?<message>\S.*)
    \z/x

    def self.parse_line(line)
      new.parse_line(line)
    end

    def parse_line(line)
      return nil if line.nil?

      match = LOG_PATTERN.match(line.to_s.strip)
      return nil unless match

      LogEntry.new(
        timestamp: match[:timestamp],
        level: match[:level],
        service: match[:service],
        message: match[:message]
      )
    end
  end
end
