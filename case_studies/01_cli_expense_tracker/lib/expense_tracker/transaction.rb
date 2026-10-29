# frozen_string_literal: true

require "json"
require "securerandom"
require "time"

module ExpenseTracker
  # Representa una transacción financiera (ingreso o gasto).
  # Los importes se almacenan en centavos (Integer) para evitar errores de
  # punto flotante. Las fechas se guardan como cadenas ISO 8601.
  Transaction = Data.define(:id, :type, :amount_cents, :category, :description, :date) do
    VALID_TYPES = %i[income expense].freeze

    def self.build(type:, amount:, category:, description:, date: Time.now.strftime("%Y-%m-%d"))
      validate_type!(type)
      cents = validate_amount!(amount)
      validate_date!(date)

      new(
        id: SecureRandom.uuid,
        type: type.to_sym,
        amount_cents: cents,
        category: category.to_s.strip,
        description: description.to_s.strip,
        date: date.to_s
      )
    end

    def amount = amount_cents / 100.0

    def income? = type == :income
    def expense? = type == :expense

    def to_display
      sign = income? ? "+" : "-"
      format("%<sign>s$%<amount>.2f  %-12<category>s  %<desc>s (%<date>s)",
             sign: sign, amount: amount, category: category, desc: description, date: date)
    end

    def to_hash
      { id: id, type: type.to_s, amount_cents: amount_cents,
        category: category, description: description, date: date }
    end

    def self.from_hash(hash)
      new(
        id: hash["id"] || hash[:id],
        type: (hash["type"] || hash[:type]).to_sym,
        amount_cents: Integer(hash["amount_cents"] || hash[:amount_cents]),
        category: hash["category"] || hash[:category],
        description: hash["description"] || hash[:description],
        date: hash["date"] || hash[:date]
      )
    end

    class << self
      private

      def validate_type!(type)
        sym = type.to_sym
        return if VALID_TYPES.include?(sym)

        raise ArgumentError, "Tipo inválido: #{type}. Usa: #{VALID_TYPES.join(', ')}"
      end

      def validate_amount!(amount)
        cents = case amount
                when Integer then amount >= 100 ? amount : (amount * 100).round
                when Float then (amount * 100).round
                when String then (Float(amount) * 100).round
                else raise ArgumentError, "Importe inválido: #{amount.inspect}"
                end
        raise ArgumentError, "El importe debe ser positivo" unless cents.positive?

        cents
      end

      def validate_date!(date)
        Date.parse(date.to_s)
      rescue Date::Error
        raise ArgumentError, "Fecha inválida: #{date}. Usa formato YYYY-MM-DD"
      end
    end
  end
end

