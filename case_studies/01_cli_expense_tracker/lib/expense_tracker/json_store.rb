# frozen_string_literal: true

require "json"
require "tempfile"

module ExpenseTracker
  # Persiste transacciones en un archivo JSON.
  #
  # Decisiones de diseño:
  # - Escritura atómica (tempfile + rename) para no perder datos si el proceso
  #   se interrumpe a mitad de escritura.
  # - La ruta del archivo se inyecta: las pruebas usan un directorio temporal.
  # - No se pretende ofrecer concurrencia segura entre procesos: para eso se
  #   necesitaría una base de datos real.
  class JsonStore
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def load_all
      return [] unless File.exist?(path)

      data = File.read(path)
      return [] if data.strip.empty?

      JSON.parse(data).map { |hash| Transaction.from_hash(hash) }
    rescue JSON::ParserError => err
      raise DataCorruptError, "El archivo #{path} no es JSON válido: #{err.message}"
    end

    def save_all(transactions)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)

      json = JSON.pretty_generate(transactions.map(&:to_hash))

      # Escritura atómica: escribe en un temporal y renombra.
      Tempfile.create(["expense_tracker", ".json"], dir) do |tmp|
        tmp.write(json)
        tmp.flush
        tmp.close
        FileUtils.mv(tmp.path, path)
      end
    end

    def append(transaction)
      all = load_all
      all << transaction
      save_all(all)
      transaction
    end

    def delete(transaction_id)
      all = load_all
      removed = all.reject { |txn| txn.id == transaction_id }
      raise NotFoundError, "Transacción #{transaction_id} no encontrada" if removed.size == all.size

      save_all(removed)
    end
  end

  class DataCorruptError < StandardError; end
  class NotFoundError < StandardError; end
end

