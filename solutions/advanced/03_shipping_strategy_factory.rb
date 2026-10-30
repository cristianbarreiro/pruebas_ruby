# frozen_string_literal: true

module Solutions
  module Advanced
    module ShippingStrategyFactory
      Quote = Data.define(:id, :strategy_code, :cost, :estimated_days)

      class BaseShipping
        def build_quote(id:, weight_kg:, distance_km:, **)
          validate_dimensions!(weight_kg, distance_km)
          Quote.new(
            id: id,
            strategy_code: code,
            cost: calculate(weight_kg: weight_kg, distance_km: distance_km, **),
            estimated_days: estimated_days(distance_km: distance_km)
          )
        end

        private

        def validate_dimensions!(weight_kg, distance_km)
          raise ArgumentError, "El peso debe ser positivo" unless weight_kg.is_a?(Numeric) && weight_kg.positive?
          return if distance_km.is_a?(Numeric) && distance_km >= 0

          raise ArgumentError, "La distancia no puede ser negativa"
        end
      end

      class StandardShipping < BaseShipping
        def code
          :standard
        end

        def calculate(weight_kg:, distance_km:, **_opts)
          validate_dimensions!(weight_kg, distance_km)
          (5.0 + (weight_kg * 1.25) + (distance_km * 0.05)).round(2)
        end

        def estimated_days(distance_km:)
          3 + (distance_km / 500.0).ceil
        end
      end

      class ExpressShipping < BaseShipping
        MAX_WEIGHT_KG = 50.0

        def code
          :express
        end

        def calculate(weight_kg:, distance_km:, **_opts)
          validate_dimensions!(weight_kg, distance_km)
          raise ArgumentError, "Peso excede límite exprés de #{MAX_WEIGHT_KG} kg" if weight_kg > MAX_WEIGHT_KG

          surcharge = weight_kg > 20.0 ? 10.0 : 0.0
          (15.0 + (weight_kg * 2.50) + (distance_km * 0.12) + surcharge).round(2)
        end

        def estimated_days(distance_km:)
          [1, (distance_km / 1000.0).ceil].max
        end
      end

      class InternationalShipping < BaseShipping
        def code
          :international
        end

        def calculate(weight_kg:, distance_km:, declared_value: 0.0, customs_rate: 0.15)
          validate_dimensions!(weight_kg, distance_km)
          raise ArgumentError, "Valor declarado inválido" if declared_value.negative? || customs_rate.negative?

          duty = declared_value * customs_rate
          (35.0 + (weight_kg * 4.00) + (distance_km * 0.08) + duty).round(2)
        end

        def estimated_days(distance_km:)
          7 + (distance_km / 1500.0).ceil
        end
      end

      class ShippingFactory
        REGISTRY = {
          standard: StandardShipping,
          express: ExpressShipping,
          international: InternationalShipping
        }.freeze

        def self.for(code)
          normalized = code.to_s.strip.downcase.to_sym
          strategy_class = REGISTRY.fetch(normalized) do
            raise ArgumentError, "Estrategia de envío desconocida: #{code.inspect}"
          end
          strategy_class.new
        end
      end

      class ShipmentRepository
        def initialize
          @quotes = {}
        end

        def save(quote)
          raise ArgumentError, "Se esperaba una instancia de Quote" unless quote.is_a?(Quote)

          @quotes[quote.id] = quote
        end

        def find(quote_id)
          @quotes[quote_id]
        end

        def all
          @quotes.values.freeze
        end

        def by_strategy(code)
          target = code.to_s.strip.downcase.to_sym
          @quotes.values.select { |quote| quote.strategy_code == target }
        end

        def total_cost
          @quotes.values.sum(0.0, &:cost).round(2)
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mod = Solutions::Advanced::ShippingStrategyFactory
  repo = mod::ShipmentRepository.new

  [
    [:standard, "SHP-01", 8.0, 400.0, {}],
    [:express, "SHP-02", 12.0, 900.0, {}],
    [:international, "SHP-03", 5.0, 3000.0, { declared_value: 200.0 }]
  ].each do |code, quote_id, weight, distance, extra|
    strategy = mod::ShippingFactory.for(code)
    repo.save(strategy.build_quote(id: quote_id, weight_kg: weight, distance_km: distance, **extra))
  end

  puts "Cotizaciones registradas: #{repo.all.size} | Costo total: $#{repo.total_cost}"
end
