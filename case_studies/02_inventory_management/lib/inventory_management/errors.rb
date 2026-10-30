# frozen_string_literal: true

module InventoryManagement
  # Excepciones de dominio del sistema de inventario.
  module Errors
    class Error < StandardError; end
    class ValidationError < Error; end
    class NotFoundError < Error; end
    class InsufficientStockError < Error; end
    class DuplicateSkuError < Error; end
  end
end
