# frozen_string_literal: true

require_relative "errors"
require_relative "stock_movement"

module InventoryManagement
  # Entidad de dominio que representa un producto en el inventario.
  class Product
    attr_reader :sku, :name, :category, :price_cents, :stock, :min_stock

    def initialize(sku:, name:, category:, price_cents:, **opts)
      @sku = validate_presence(sku, "SKU").upcase
      @name = validate_presence(name, "nombre")
      @category = validate_presence(category, "categoría").downcase
      @price_cents = validate_positive_int(price_cents, "precio")
      @stock = validate_non_negative_int(opts.fetch(:stock, 0), "stock")
      @min_stock = validate_non_negative_int(opts.fetch(:min_stock, 0), "stock mínimo")
    end

    def low_stock?
      @stock <= @min_stock
    end

    def inventory_value_cents
      @price_cents * @stock
    end

    def apply_movement(movement)
      new_stock = @stock + movement.signed_delta
      if new_stock.negative?
        raise Errors::InsufficientStockError,
              "Stock insuficiente para #{@sku} (disponible: #{@stock}, solicitado: #{movement.quantity})"
      end

      @stock = new_stock
      self
    end

    def update(name: nil, category: nil, price_cents: nil, min_stock: nil)
      @name = validate_presence(name, "nombre") unless name.nil?
      @category = validate_presence(category, "categoría").downcase unless category.nil?
      @price_cents = validate_positive_int(price_cents, "precio") unless price_cents.nil?
      @min_stock = validate_non_negative_int(min_stock, "stock mínimo") unless min_stock.nil?
      self
    end

    def to_h
      {
        sku: @sku,
        name: @name,
        category: @category,
        price_cents: @price_cents,
        stock: @stock,
        min_stock: @min_stock
      }
    end

    def self.from_h(raw)
      data = raw.transform_keys(&:to_sym)
      new(
        sku: data[:sku],
        name: data[:name],
        category: data[:category],
        price_cents: data[:price_cents],
        stock: data.fetch(:stock, 0),
        min_stock: data.fetch(:min_stock, 0)
      )
    end

    private

    def validate_presence(val, field_name)
      text = val.to_s.strip
      raise Errors::ValidationError, "El campo #{field_name} es obligatorio" if text.empty?

      text
    end

    def validate_positive_int(val, field_name)
      unless val.is_a?(Integer) && val.positive?
        raise Errors::ValidationError, "El #{field_name} debe ser un entero positivo"
      end

      val
    end

    def validate_non_negative_int(val, field_name)
      raise Errors::ValidationError, "El #{field_name} no puede ser negativo" if !val.is_a?(Integer) || val.negative?

      val
    end
  end
end
