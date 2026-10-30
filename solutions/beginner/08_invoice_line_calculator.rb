# frozen_string_literal: true

module Solutions
  module Beginner
    # Calcula el desglose inmutable de una línea de factura operando en centavos.
    module InvoiceLineCalculator
      LineResult = Data.define(
        :description,
        :quantity,
        :gross_cents,
        :discount_cents,
        :net_cents,
        :tax_cents,
        :total_cents
      )

      module_function

      def calculate_line(description, quantity, unit_price_cents:, discount_percent: 0, tax_percent: 19)
        validate_line_args!(description, quantity, unit_price_cents, discount_percent, tax_percent)

        gross_cents = quantity * unit_price_cents
        discount_cents = percentage_of(gross_cents, discount_percent)
        net_cents = gross_cents - discount_cents
        tax_cents = percentage_of(net_cents, tax_percent)

        LineResult.new(
          description: description.strip,
          quantity: quantity,
          gross_cents: gross_cents,
          discount_cents: discount_cents,
          net_cents: net_cents,
          tax_cents: tax_cents,
          total_cents: net_cents + tax_cents
        )
      end

      def validate_line_args!(description, quantity, unit_price_cents, discount_percent, tax_percent)
        validate_description_and_qty!(description, quantity)
        validate_price_and_rates!(unit_price_cents, discount_percent, tax_percent)
      end
      private_class_method :validate_line_args!

      def validate_description_and_qty!(description, quantity)
        valid_desc = description.is_a?(String) && !description.strip.empty?
        valid_qty = quantity.is_a?(Integer) && quantity.positive?
        raise ArgumentError, "La descripción no puede estar vacía" unless valid_desc
        raise ArgumentError, "La cantidad debe ser un entero positivo" unless valid_qty
      end
      private_class_method :validate_description_and_qty!

      def validate_price_and_rates!(unit_price_cents, discount_percent, tax_percent)
        valid_price = unit_price_cents.is_a?(Integer) && unit_price_cents >= 0
        valid_disc = discount_percent.is_a?(Numeric) && discount_percent.between?(0, 100)
        valid_tax = tax_percent.is_a?(Numeric) && tax_percent >= 0
        raise ArgumentError, "El precio unitario debe ser un entero no negativo" unless valid_price
        raise ArgumentError, "El porcentaje de descuento debe estar entre 0 y 100" unless valid_disc
        raise ArgumentError, "El porcentaje de impuesto no puede ser negativo" unless valid_tax
      end
      private_class_method :validate_price_and_rates!

      def percentage_of(amount_cents, percent)
        (amount_cents * (percent / 100.0)).round
      end
      private_class_method :percentage_of
    end
  end
end

if $PROGRAM_NAME == __FILE__
  line = Solutions::Beginner::InvoiceLineCalculator.calculate_line(
    "Licencia Anual Pro",
    2,
    unit_price_cents: 10_000,
    discount_percent: 10,
    tax_percent: 19
  )
  puts line.inspect
end
