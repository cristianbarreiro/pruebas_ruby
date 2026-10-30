# frozen_string_literal: true

# = Motor de precios de pedidos por composición

module Solutions
  module Intermediate
    module OrderPricingEngine
      LineItem = Data.define(:sku, :unit_price_cents, :quantity) do
        def subtotal_cents
          unit_price_cents * quantity
        end
      end

      PricingBreakdown = Data.define(
        :subtotal_cents,
        :discount_cents,
        :taxable_cents,
        :tax_cents,
        :total_cents
      )

      class NoDiscount
        def discount_for(_subtotal_cents)
          0
        end
      end

      class PercentageDiscount
        attr_reader :percent

        def initialize(percent)
          raise ArgumentError, "Percent must be between 0 and 100" unless (0..100).cover?(percent)

          @percent = percent
        end

        def discount_for(subtotal_cents)
          (subtotal_cents * @percent / 100.0).round
        end
      end

      class ThresholdDiscount
        attr_reader :threshold_cents, :discount_cents

        def initialize(threshold_cents:, discount_cents:)
          if threshold_cents.negative? || discount_cents.negative?
            raise ArgumentError, "Threshold and discount must be non-negative"
          end

          @threshold_cents = threshold_cents
          @discount_cents = discount_cents
        end

        def discount_for(subtotal_cents)
          return 0 if subtotal_cents < @threshold_cents

          [@discount_cents, subtotal_cents].min
        end
      end

      class TaxPolicy
        attr_reader :rate_percent

        def initialize(rate_percent)
          raise ArgumentError, "Tax rate must be non-negative" if rate_percent.negative?

          @rate_percent = rate_percent
        end

        def tax_for(taxable_cents)
          (taxable_cents * @rate_percent / 100.0).round
        end
      end

      class Order
        attr_reader :discount, :tax_policy

        def initialize(items: [], discount: NoDiscount.new, tax_policy: TaxPolicy.new(0))
          @items = []
          @discount = discount
          @tax_policy = tax_policy
          items.each { |item| add_line_item(item) }
        end

        def items
          @items.dup.freeze
        end

        def add_item(sku:, unit_price_cents:, quantity: 1)
          validate_item!(sku, unit_price_cents, quantity)
          item = LineItem.new(sku: sku, unit_price_cents: unit_price_cents, quantity: quantity)
          @items << item
          item
        end

        def subtotal_cents
          @items.sum(&:subtotal_cents)
        end

        def pricing_breakdown
          sub = subtotal_cents
          disc = [@discount.discount_for(sub), sub].min
          taxable = sub - disc
          tax = @tax_policy.tax_for(taxable)
          PricingBreakdown.new(
            subtotal_cents: sub, discount_cents: disc, taxable_cents: taxable,
            tax_cents: tax, total_cents: taxable + tax
          )
        end

        private

        def add_line_item(item)
          add_item(sku: item.sku, unit_price_cents: item.unit_price_cents, quantity: item.quantity)
        end

        def validate_item!(sku, unit_price_cents, quantity)
          raise ArgumentError, "SKU cannot be empty" if sku.to_s.strip.empty?
          raise ArgumentError, "Unit price must be >= 0" if unit_price_cents.negative?
          raise ArgumentError, "Quantity must be > 0" unless quantity.positive?
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  engine = Solutions::Intermediate::OrderPricingEngine
  order = engine::Order.new(
    discount: engine::PercentageDiscount.new(10),
    tax_policy: engine::TaxPolicy.new(21)
  )
  order.add_item(sku: "BOOK-01", unit_price_cents: 2_500, quantity: 2)
  puts order.pricing_breakdown.inspect
end
