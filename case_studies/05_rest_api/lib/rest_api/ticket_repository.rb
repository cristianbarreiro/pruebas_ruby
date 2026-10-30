# frozen_string_literal: true

require "fileutils"
require "json"
require "tempfile"
require_relative "ticket"

module RestApi
  # Repositorio de persistencia de tickets en archivo JSON local (o en memoria si
  # la ruta es nil), configurable mediante la variable de entorno STORAGE_PATH.
  class TicketRepository
    DEFAULT_STORAGE = "storage/tickets.json"

    attr_reader :storage_path

    def initialize(storage_path: ENV.fetch("STORAGE_PATH", DEFAULT_STORAGE))
      @storage_path = storage_path
      @mutex = Mutex.new
      @memory_records = []
    end

    def all
      @mutex.synchronize { read_records.dup }
    end

    def find(ticket_id)
      @mutex.synchronize do
        read_records.find { |item| item.id == ticket_id }
      end
    end

    def save(ticket)
      @mutex.synchronize do
        records = read_records
        idx = records.index { |item| item.id == ticket.id }
        idx ? records[idx] = ticket : records << ticket
        write_records(records)
        ticket
      end
    end

    def delete(ticket_id)
      @mutex.synchronize do
        records = read_records
        removed = records.find { |item| item.id == ticket_id }
        return nil unless removed

        write_records(records.reject { |item| item.id == ticket_id })
        removed
      end
    end

    private

    def read_records
      return @memory_records if @storage_path.nil? || @storage_path.strip.empty?
      return [] unless File.exist?(@storage_path)

      raw = File.read(@storage_path, encoding: "UTF-8")
      return [] if raw.strip.empty?

      JSON.parse(raw).map { |row| Ticket.from_hash(row) }
    end

    def write_records(records)
      if @storage_path.nil? || @storage_path.strip.empty?
        @memory_records = records
        return
      end

      atomic_write(JSON.pretty_generate(records.map(&:to_h)))
    end

    def atomic_write(payload)
      dir = File.dirname(@storage_path)
      FileUtils.mkdir_p(dir)
      Tempfile.create(["tickets", ".tmp"], dir) do |tmp|
        tmp.write(payload)
        tmp.flush
        tmp.close
        FileUtils.mv(tmp.path, @storage_path)
      end
    end
  end
end
