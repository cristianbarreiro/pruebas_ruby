# frozen_string_literal: true

require_relative "errors"
require_relative "product"
require_relative "stock_movement"

module InventoryManagement
  # Servicio de aplicación que orquesta reglas de inventario y persistencia.
  class InventoryService
    attr_reader :movements

    def initialize(repository: nil)
      @repository = repository
      loaded = @repository ? @repository.load_data : { products: [], movements: [] }
      @products = loaded[:products].to_h { |prod| [prod.sku, prod] }
      @movements = loaded[:movements].dup
    end

    def create_product(sku:, name:, category:, price_cents:, **)
      norm_sku = sku.to_s.strip.upcase
      raise Errors::DuplicateSkuError, "El SKU #{norm_sku} ya está registrado" if @products.key?(norm_sku)

      product = Product.new(
        sku: norm_sku, name: name, category: category, price_cents: price_cents, **
      )
      @products[product.sku] = product
      persist!
      product
    end
    alias add_product create_product

    def update_product(sku, **changes)
      product = find_product(sku)
      product.update(**changes)
      persist!
      product
    end

    def find_product(sku)
      norm_sku = sku.to_s.strip.upcase
      @products.fetch(norm_sku) do
        raise Errors::NotFoundError, "No se encontró el producto con SKU #{norm_sku}"
      end
    end

    def delete_product(sku)
      product = find_product(sku)
      @products.delete(product.sku)
      persist!
      product
    end

    def all_products
      @products.values.sort_by(&:sku)
    end

    def record_entry(sku:, quantity:, reason:, timestamp: nil)
      apply_stock_movement(sku: sku, type: :in, quantity: quantity, reason: reason, timestamp: timestamp)
    end

    def record_exit(sku:, quantity:, reason:, timestamp: nil)
      apply_stock_movement(sku: sku, type: :out, quantity: quantity, reason: reason, timestamp: timestamp)
    end

    def movements_for(sku)
      norm_sku = sku.to_s.strip.upcase
      @movements.select { |mov| mov.sku == norm_sku }
    end

    def search(query = nil, category: nil)
      term = query.to_s.strip.downcase
      cat_filter = category.to_s.strip.downcase
      all_products.select do |prod|
        matches_query?(prod, term) && matches_category?(prod, cat_filter)
      end
    end

    def low_stock_products
      all_products.select(&:low_stock?)
    end

    def valuation_report
      items = all_products
      {
        total_skus: items.size,
        total_units: items.sum(&:stock),
        total_value_cents: items.sum(&:inventory_value_cents),
        low_stock_count: low_stock_products.size,
        by_category: build_category_breakdown(items)
      }
    end

    private

    def apply_stock_movement(sku:, type:, quantity:, reason:, timestamp:)
      product = find_product(sku)
      movement = StockMovement.new(
        sku: product.sku, type: type, quantity: quantity, reason: reason, timestamp: timestamp
      )
      product.apply_movement(movement)
      @movements << movement
      persist!
      movement
    end

    def matches_query?(prod, term)
      return true if term.empty?

      [prod.sku, prod.name, prod.category].any? { |field| field.downcase.include?(term) }
    end

    def matches_category?(prod, cat_filter)
      return true if cat_filter.empty?

      prod.category == cat_filter
    end

    def build_category_breakdown(items)
      items.group_by(&:category).transform_values do |group|
        {
          skus: group.size,
          units: group.sum(&:stock),
          value_cents: group.sum(&:inventory_value_cents)
        }
      end
    end

    def persist!
      @repository&.save_data(products: @products.values, movements: @movements)
    end
  end
end
