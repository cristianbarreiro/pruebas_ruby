# frozen_string_literal: true

require "fileutils"
require "json"
require "tempfile"

module ExpenseTracker
  # Persiste transacciones en un archivo JSON local.
  #
  # Decisiones de diseño:
  # - Escritura atómica (archivo temporal en el mismo directorio + rename)
  #   para evitar archivos truncados si el proceso se interrumpe.
  # - La ruta se inyecta por constructor para aislar pruebas con Dir.mktmpdir.
  class JsonStore
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def load_all
      return [] unless File.exist?(path)

      raw = File.read(path, encoding: "UTF-8")
      return [] if raw.strip.empty?

      parsed = JSON.parse(raw)
      raise DataCorruptError, "Se esperaba un array JSON en #{path}" unless parsed.is_a?(Array)

      parsed.map { |entry| Transaction.from_hash(entry) }
    rescue JSON::ParserError, ArgumentError, TypeError => e
      raise DataCorruptError, "El archivo #{path} contiene datos corruptos: #{e.message}"
    end

    def save_all(transactions)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      payload = JSON.pretty_generate(transactions.map(&:to_hash))

      Tempfile.create(["expenses", ".tmp"], dir) do |tmp|
        tmp.write(payload)
        tmp.flush
        tmp.close
        FileUtils.mv(tmp.path, path)
      end
    end

    def append(transaction)
      transactions = load_all
      transactions << transaction
      save_all(transactions)
      transaction
    end

    def delete(transaction_id)
      transactions = load_all
      remaining = transactions.reject { |txn| txn.id == transaction_id || txn.id.start_with?(transaction_id) }
      raise NotFoundError, "Transacción #{transaction_id} no encontrada" if remaining.size == transactions.size

      save_all(remaining)
    end
  end

  class DataCorruptError < StandardError; end
  class NotFoundError < StandardError; end
end
