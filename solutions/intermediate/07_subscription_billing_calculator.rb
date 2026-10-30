# frozen_string_literal: true

# = Calculadora de prorrateo para facturación de suscripciones

require "date"

module Solutions
  module Intermediate
    module SubscriptionBillingCalculator
      PlanChangeQuote = Data.define(
        :days_in_month,
        :used_days,
        :remaining_days,
        :unused_credit_cents,
        :new_plan_charge_cents,
        :net_amount_cents
      )

      module_function

      def calculate_change(current_price_cents:, new_price_cents:, billing_month_start:, change_date:)
        validate_prices!(current_price_cents, new_price_cents)
        days_in_month = validate_dates!(billing_month_start, change_date)
        used_days = change_date.day - 1
        remaining_days = days_in_month - used_days
        build_quote(current_price_cents, new_price_cents, days_in_month, used_days, remaining_days)
      end

      def validate_prices!(current_price_cents, new_price_cents)
        valid_curr = current_price_cents.is_a?(Integer) && current_price_cents >= 0
        valid_new = new_price_cents.is_a?(Integer) && new_price_cents >= 0
        raise ArgumentError, "Prices must be non-negative Integers" unless valid_curr && valid_new
      end

      def validate_dates!(billing_month_start, change_date)
        raise ArgumentError, "Expected Date instances" unless billing_month_start.is_a?(Date) && change_date.is_a?(Date)
        raise ArgumentError, "billing_month_start must be day 1" unless billing_month_start.day == 1

        month_end = Date.new(billing_month_start.year, billing_month_start.month, -1)
        unless (billing_month_start..month_end).cover?(change_date)
          raise ArgumentError, "change_date must be within the billing month"
        end

        month_end.day
      end

      def build_quote(current_price, new_price, days_in_month, used_days, remaining_days)
        credit = prorate(current_price, remaining_days, days_in_month)
        charge = prorate(new_price, remaining_days, days_in_month)
        PlanChangeQuote.new(
          days_in_month: days_in_month,
          used_days: used_days,
          remaining_days: remaining_days,
          unused_credit_cents: credit,
          new_plan_charge_cents: charge,
          net_amount_cents: charge - credit
        )
      end

      def prorate(price_cents, remaining_days, days_in_month)
        (price_cents * remaining_days.to_f / days_in_month).round
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  calc = Solutions::Intermediate::SubscriptionBillingCalculator
  quote = calc.calculate_change(
    current_price_cents: 3_000,
    new_price_cents: 6_000,
    billing_month_start: Date.new(2026, 4, 1),
    change_date: Date.new(2026, 4, 16)
  )
  puts quote.inspect
end
