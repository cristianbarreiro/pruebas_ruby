# frozen_string_literal: true

# = Jerarquía de excepciones y reintentos en pasarela de pagos

module Solutions
  module Intermediate
    module PaymentGatewayErrors
      class PaymentError < StandardError; end
      class TransientGatewayError < PaymentError; end
      class InvalidCardError < PaymentError; end

      ChargeResult = Data.define(:transaction_id, :amount_cents, :attempts)

      class PaymentProcessor
        attr_reader :gateway, :max_retries

        def initialize(gateway:, max_retries: 2)
          raise ArgumentError, "max_retries must be >= 0" unless max_retries.is_a?(Integer) && max_retries >= 0

          @gateway = gateway
          @max_retries = max_retries
        end

        def charge(card_token:, amount_cents:)
          validate_charge_args!(card_token, amount_cents)
          attempts = 0
          begin
            attempts += 1
            tx_id = @gateway.process(card_token: card_token, amount_cents: amount_cents)
            ChargeResult.new(transaction_id: tx_id, amount_cents: amount_cents, attempts: attempts)
          rescue TransientGatewayError
            retry if attempts <= @max_retries
            raise
          end
        end

        private

        def validate_charge_args!(card_token, amount_cents)
          raise ArgumentError, "card_token cannot be empty" if card_token.to_s.strip.empty?
          return if amount_cents.is_a?(Integer) && amount_cents.positive?

          raise ArgumentError, "amount_cents must be a positive Integer"
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mod = Solutions::Intermediate::PaymentGatewayErrors
  calls = 0
  gateway = Object.new
  gateway.define_singleton_method(:process) do |card_token:, amount_cents:|
    calls += 1
    raise mod::TransientGatewayError, "Gateway timeout" if calls < 3

    "tx_#{card_token}_#{amount_cents}"
  end
  processor = mod::PaymentProcessor.new(gateway: gateway, max_retries: 3)
  puts processor.charge(card_token: "tok_visa", amount_cents: 4_500).inspect
end
