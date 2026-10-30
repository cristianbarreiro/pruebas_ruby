# frozen_string_literal: true

require "date"
require "json"
require "securerandom"

module ExpenseTracker
  VALID_TYPES = %i[income expense].freeze

  # Representa una transacción financiera inmutable (ingreso o gasto).
  # Los importes se almacenan internamente en centavos (Integer) para evitar
  # errores de representación en coma flotante (IEEE 754).
  Transaction = Data.define(:id, :type, :amount_cents, :category, :description, :date) do
    def self.build(type:, amount:, category:, description:, date: Date.today.iso8601)
      normalized_type = validate_type!(type)
      cents = parse_amount_to_cents!(amount)
      normalized_cat = validate_text!(category, "La categoría")
      normalized_desc = validate_text!(description, "La descripción")
      normalized_date = validate_date!(date)

      new(
        id: SecureRandom.uuid,
        type: normalized_type,
        amount_cents: cents,
        category: normalized_cat,
        description: normalized_desc,
        date: normalized_date
      )
    end

    def amount
      amount_cents / 100.0
    end

    def signed_cents
      income? ? amount_cents : -amount_cents
    end

    def income? = type == :income
    def expense? = type == :expense

    def to_display
      sign = income? ? "+" : "-"
      format(
        "%<date>s | %<id>-8s | %<sign>s$%<amount>9.2f | %-14<category>s | %<desc>s",
        date: date, id: id[0, 8], sign: sign, amount: amount, category: category, desc: description
      )
    end

    def to_hash
      {
        id: id,
        type: type.to_s,
        amount_cents: amount_cents,
        category: category,
        description: description,
        date: date
      }
    end

    def self.from_hash(hash)
      data = hash.transform_keys(&:to_sym)
      validate_type!(data[:type])
      cents = Integer(data[:amount_cents])
      raise ArgumentError, "amount_cents debe ser positivo" unless cents.positive?

      new(
        id: validate_text!(data[:id], "El ID"),
        type: data[:type].to_sym,
        amount_cents: cents,
        category: validate_text!(data[:category], "La categoría"),
        description: validate_text!(data[:description], "La descripción"),
        date: validate_date!(data[:date])
      )
    end

    class << self
      private

      def validate_type!(type)
        raise ArgumentError, "El tipo es obligatorio" if type.nil? || type.to_s.strip.empty?

        sym = type.to_sym
        return sym if VALID_TYPES.include?(sym)

        raise ArgumentError, "Tipo inválido: #{type}. Usa: #{VALID_TYPES.join(", ")}"
      end

      def parse_amount_to_cents!(amount)
        numeric = Float(amount)
        raise ArgumentError, "El importe debe ser finito y positivo" unless numeric.finite? && numeric.positive?

        cents = (numeric * 100).round
        raise ArgumentError, "El importe debe ser al menos 0.01" unless cents.positive?

        cents
      rescue TypeError, ArgumentError
        raise ArgumentError, "Importe inválido: #{amount.inspect}. Debe ser un número positivo"
      end

      def validate_text!(value, label)
        clean = value.to_s.strip
        raise ArgumentError, "#{label} no puede estar vacía" if clean.empty?

        clean
      end

      def validate_date!(date)
        Date.iso8601(date.to_s.strip).iso8601
      rescue Date::Error
        raise ArgumentError, "Fecha inválida: #{date.inspect}. Usa formato YYYY-MM-DD"
      end
    end
  end
end
