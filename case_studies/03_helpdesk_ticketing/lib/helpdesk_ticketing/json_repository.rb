# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "ticket"

module HelpdeskTicketing
  # Repositorio JSON que persiste tickets y su historial de forma atómica.
  class JsonRepository
    attr_reader :file_path

    def initialize(file_path)
      @file_path = File.expand_path(file_path)
    end

    def load_tickets
      return [] unless File.exist?(@file_path)

      parsed = JSON.parse(File.read(@file_path, encoding: "UTF-8"), symbolize_names: true)
      rows = parsed.is_a?(Hash) ? parsed.fetch(:tickets, []) : parsed
      rows.map { |row| Ticket.from_h(row) }
    end

    def save_tickets(tickets)
      FileUtils.mkdir_p(File.dirname(@file_path))
      data = { tickets: tickets.sort_by(&:id).map(&:to_h) }
      write_atomically("#{JSON.pretty_generate(data)}\n")
    end

    private

    def write_atomically(content)
      temp_path = "#{@file_path}.tmp.#{Process.pid}.#{object_id}"
      File.open(temp_path, "w:UTF-8") do |file|
        file.write(content)
        file.flush
      end
      File.rename(temp_path, @file_path)
    ensure
      FileUtils.rm_f(temp_path) if temp_path && File.exist?(temp_path)
    end
  end
end
