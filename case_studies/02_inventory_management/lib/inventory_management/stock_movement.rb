# frozen_string_literal: true

require "time"
require_relative "errors"

module InventoryManagement
  MOVEMENT_TYPES = %i[in out].freeze

  # Representa un movimiento inmutable de stock (:in o :out).
  StockMovement = Data.define(:sku, :type, :quantity, :reason, :timestamp) do
    def initialize(type:, quantity:, reason:, sku: nil, timestamp: nil)
      norm_type = normalize_type(type)
      norm_qty = validate_quantity(quantity)
      norm_reason = validate_reason(reason)
      norm_sku = sku.nil? ? nil : sku.to_s.strip.upcase
      norm_time = normalize_timestamp(timestamp)
      super(sku: norm_sku, type: norm_type, quantity: norm_qty, reason: norm_reason, timestamp: norm_time)
    end

    def entry?
      type == :in
    end

    def exit?
      type == :out
    end

    def signed_delta
      entry? ? quantity : -quantity
    end

    def to_h
      { sku: sku, type: type.to_s, quantity: quantity, reason: reason, timestamp: timestamp }
    end

    def self.from_h(raw)
      data = raw.transform_keys(&:to_sym)
      new(
        sku: data[:sku],
        type: data[:type],
        quantity: data[:quantity],
        reason: data[:reason],
        timestamp: data[:timestamp]
      )
    end

    private

    def normalize_type(val)
      sym = val.to_s.strip.downcase.to_sym
      return sym if MOVEMENT_TYPES.include?(sym)

      raise Errors::ValidationError, "Tipo de movimiento inválido: #{val}"
    end

    def validate_quantity(val)
      unless val.is_a?(Integer) && val.positive?
        raise Errors::ValidationError, "La cantidad debe ser un entero positivo"
      end

      val
    end

    def validate_reason(val)
      text = val.to_s.strip
      raise Errors::ValidationError, "El motivo del movimiento es obligatorio" if text.empty?

      text
    end

    def normalize_timestamp(val)
      return Time.now.utc.iso8601 if val.nil? || val.to_s.strip.empty?
      return val.utc.iso8601 if val.is_a?(Time)

      val.to_s
    end
  end
end
