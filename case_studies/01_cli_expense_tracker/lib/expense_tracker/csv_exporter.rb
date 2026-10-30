# frozen_string_literal: true

require "csv"
require "fileutils"
require "tempfile"

module ExpenseTracker
  # Exporta una colección de transacciones a formato CSV de forma atómica.
  class CsvExporter
    HEADERS = %w[id date type category amount description].freeze

    def self.export(transactions, destination_path)
      dir = File.dirname(destination_path)
      FileUtils.mkdir_p(dir)

      Tempfile.create(["expenses_csv", ".tmp"], dir) do |tmp|
        write_rows(tmp, transactions)
        tmp.flush
        tmp.close
        FileUtils.mv(tmp.path, destination_path)
      end
      destination_path
    end

    def self.write_rows(io_stream, transactions)
      csv = CSV.new(io_stream, headers: HEADERS, write_headers: true)
      transactions.each do |txn|
        csv << [
          txn.id,
          txn.date,
          txn.type.to_s,
          txn.category,
          format("%.2f", txn.amount),
          txn.description
        ]
      end
    end
    private_class_method :write_rows
  end
end
