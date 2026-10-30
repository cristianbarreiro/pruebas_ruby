# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "product"
require_relative "stock_movement"

module InventoryManagement
  # Repositorio JSON con escritura atómica mediante archivo temporal y renombrado.
  class JsonRepository
    attr_reader :file_path

    def initialize(file_path)
      @file_path = File.expand_path(file_path)
    end

    def load_data
      return { products: [], movements: [] } unless File.exist?(@file_path)

      parsed = JSON.parse(File.read(@file_path, encoding: "UTF-8"), symbolize_names: true)
      {
        products: parsed.fetch(:products, []).map { |row| Product.from_h(row) },
        movements: parsed.fetch(:movements, []).map { |row| StockMovement.from_h(row) }
      }
    end

    def save_data(products:, movements:)
      FileUtils.mkdir_p(File.dirname(@file_path))
      payload = serialize_payload(products, movements)
      write_atomically(payload)
    end

    private

    def serialize_payload(products, movements)
      data = {
        products: products.sort_by(&:sku).map(&:to_h),
        movements: movements.map(&:to_h)
      }
      "#{JSON.pretty_generate(data)}\n"
    end

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
