# frozen_string_literal: true

module Solutions
  module Beginner
    # Calcula el resumen financiero de un carrito de compras operando en centavos enteros.
    module ShoppingCartSummary
      module_function

      def summarize(items, discount_rate: 0.0, tax_rate: 0.19)
        validate_inputs!(items, discount_rate, tax_rate)

        subtotal_cents = items.sum { |item| item[:unit_price_cents] * item[:quantity] }
        discount_cents = (subtotal_cents * discount_rate).round
        net_cents = subtotal_cents - discount_cents
        tax_cents = (net_cents * tax_rate).round

        {
          subtotal_cents: subtotal_cents,
          discount_cents: discount_cents,
          tax_cents: tax_cents,
          total_cents: net_cents + tax_cents,
          line_count: items.size
        }
      end

      def validate_inputs!(items, discount_rate, tax_rate)
        raise ArgumentError, "La lista de ítems debe ser un Array" unless items.is_a?(Array)

        validate_rates!(discount_rate, tax_rate)
        items.each { |item| validate_item!(item) }
      end
      private_class_method :validate_inputs!

      def validate_rates!(discount_rate, tax_rate)
        valid_discount = discount_rate.is_a?(Numeric) && discount_rate.between?(0.0, 1.0)
        valid_tax = tax_rate.is_a?(Numeric) && tax_rate >= 0.0
        raise ArgumentError, "Tasa de descuento inválida" unless valid_discount
        raise ArgumentError, "Tasa de impuesto inválida" unless valid_tax
      end
      private_class_method :validate_rates!

      def validate_item!(item)
        raise ArgumentError, "Cada ítem debe ser un Hash" unless item.is_a?(Hash)
        return if valid_name?(item[:name]) && valid_price?(item[:unit_price_cents]) && valid_qty?(item[:quantity])

        raise ArgumentError, "Ítem inválido: #{item.inspect}"
      end
      private_class_method :validate_item!

      def valid_name?(name)
        name.is_a?(String) && !name.strip.empty?
      end
      private_class_method :valid_name?

      def valid_price?(price)
        price.is_a?(Integer) && price >= 0
      end
      private_class_method :valid_price?

      def valid_qty?(qty)
        qty.is_a?(Integer) && qty.positive?
      end
      private_class_method :valid_qty?
    end
  end
end

if $PROGRAM_NAME == __FILE__
  cart = [
    { name: "Teclado Mecánico", unit_price_cents: 50_000, quantity: 1 },
    { name: "Cable USB-C", unit_price_cents: 10_000, quantity: 2 }
  ]
  puts Solutions::Beginner::ShoppingCartSummary.summarize(cart, discount_rate: 0.10, tax_rate: 0.19).inspect
end
