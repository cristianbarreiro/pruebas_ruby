# frozen_string_literal: true

module Solutions
  module Advanced
    module TariffRulesRefactoring
      ConsumptionContext = Data.define(:customer_type, :kwh, :peak_ratio, :green_certified, :social_tariff)

      class ResidentialBaseRule
        TIER_LIMIT_KWH = 200
        BASE_RATE = 0.12
        EXCESS_RATE = 0.18

        def code
          :residential_base
        end

        def applies?(ctx)
          ctx.customer_type == :residential
        end

        def apply(ctx, _subtotal)
          base_kwh = [ctx.kwh, TIER_LIMIT_KWH].min
          excess_kwh = [ctx.kwh - TIER_LIMIT_KWH, 0].max
          (base_kwh * BASE_RATE) + (excess_kwh * EXCESS_RATE)
        end
      end

      class CommercialBaseRule
        RATE_PER_KWH = 0.22
        DEMAND_CHARGE = 25.0

        def code
          :commercial_base
        end

        def applies?(ctx)
          ctx.customer_type == :commercial
        end

        def apply(ctx, _subtotal)
          return 0.0 if ctx.kwh.zero?

          DEMAND_CHARGE + (ctx.kwh * RATE_PER_KWH)
        end
      end

      class PeakHourSurchargeRule
        THRESHOLD = 0.3
        SURCHARGE_RATE = 0.06

        def code
          :peak_surcharge
        end

        def applies?(ctx)
          ctx.kwh.positive? && ctx.peak_ratio > THRESHOLD
        end

        def apply(ctx, _subtotal)
          ctx.kwh * ctx.peak_ratio * SURCHARGE_RATE
        end
      end

      class GreenEnergyDiscountRule
        DISCOUNT_FACTOR = -0.10

        def code
          :green_discount
        end

        def applies?(ctx)
          ctx.green_certified == true && ctx.kwh.positive?
        end

        def apply(_ctx, subtotal)
          subtotal * DISCOUNT_FACTOR
        end
      end

      class SocialTariffDiscountRule
        MAX_SOCIAL_KWH = 250
        DISCOUNT_FACTOR = -0.25

        def code
          :social_discount
        end

        def applies?(ctx)
          ctx.customer_type == :residential && ctx.social_tariff == true &&
            ctx.kwh.positive? && ctx.kwh <= MAX_SOCIAL_KWH
        end

        def apply(_ctx, subtotal)
          subtotal * DISCOUNT_FACTOR
        end
      end

      class TariffEngine
        VALID_CUSTOMERS = %i[residential commercial].freeze

        def self.default_rules
          [
            ResidentialBaseRule.new,
            CommercialBaseRule.new,
            PeakHourSurchargeRule.new,
            GreenEnergyDiscountRule.new,
            SocialTariffDiscountRule.new
          ].freeze
        end

        def initialize(rules: self.class.default_rules)
          @rules = rules.dup.freeze
        end

        def calculate(input)
          ctx = build_and_validate_context(input)
          subtotal, breakdown = evaluate_rules(ctx)
          {
            customer_type: ctx.customer_type,
            kwh: ctx.kwh,
            total: [subtotal.round(2), 0.0].max,
            breakdown: breakdown
          }
        end

        private

        def build_and_validate_context(input)
          ctx = input.is_a?(ConsumptionContext) ? input : coerce_hash(input)
          validate_context!(ctx)
          ctx
        end

        def coerce_hash(attrs)
          ConsumptionContext.new(
            customer_type: attrs[:customer_type]&.to_sym,
            kwh: attrs[:kwh],
            peak_ratio: attrs.fetch(:peak_ratio, 0.0),
            green_certified: attrs.fetch(:green_certified, false),
            social_tariff: attrs.fetch(:social_tariff, false)
          )
        end

        def validate_context!(ctx)
          raise ArgumentError, "Tipo de cliente inválido" unless VALID_CUSTOMERS.include?(ctx.customer_type)
          raise ArgumentError, "El consumo kwh debe ser >= 0" unless ctx.kwh.is_a?(Numeric) && ctx.kwh >= 0
          return if ctx.peak_ratio.is_a?(Numeric) && ctx.peak_ratio.between?(0.0, 1.0)

          raise ArgumentError, "peak_ratio debe estar entre 0.0 y 1.0"
        end

        def evaluate_rules(ctx)
          subtotal = 0.0
          breakdown = []
          @rules.each do |rule|
            next unless rule.applies?(ctx)

            delta = rule.apply(ctx, subtotal)
            next if delta.zero? && subtotal.zero? && ctx.kwh.zero?

            subtotal += delta
            breakdown << { rule: rule.code, amount: delta.round(2) }
          end
          [subtotal, breakdown]
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  engine = Solutions::Advanced::TariffRulesRefactoring::TariffEngine.new
  bill = engine.calculate(
    customer_type: :residential,
    kwh: 300,
    peak_ratio: 0.5,
    green_certified: true,
    social_tariff: false
  )
  puts "Factura calculada con motor de reglas:"
  p bill
end
