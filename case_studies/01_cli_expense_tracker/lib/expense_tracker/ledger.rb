# frozen_string_literal: true

module ExpenseTracker
  # Capa de dominio que coordina registro, filtrado y cálculo de balances
  # sin acoplarse a la consola ni al formato de archivo.
  class Ledger
    Summary = Data.define(:income_cents, :expense_cents, :balance_cents, :by_category, :count) do
      def income = income_cents / 100.0
      def expense = expense_cents / 100.0
      def balance = balance_cents / 100.0
    end

    def initialize(store)
      @store = store
    end

    def record(type:, amount:, category:, description:, date: Date.today.iso8601)
      transaction = Transaction.build(
        type: type,
        amount: amount,
        category: category,
        description: description,
        date: date
      )
      @store.append(transaction)
    end

    def delete(transaction_id)
      @store.delete(transaction_id)
    end

    def list(**filters)
      @store.load_all
            .select { |txn| matches_filters?(txn, filters) }
            .sort_by { |txn| [txn.date, txn.id] }
    end

    def summarize(transactions = @store.load_all)
      income = transactions.select(&:income?).sum(&:amount_cents)
      expense = transactions.select(&:expense?).sum(&:amount_cents)
      by_cat = category_breakdown(transactions)

      Summary.new(
        income_cents: income,
        expense_cents: expense,
        balance_cents: income - expense,
        by_category: by_cat,
        count: transactions.size
      )
    end

    private

    def matches_filters?(txn, filters)
      matches_type_and_category?(txn, filters[:type], filters[:category]) &&
        matches_date_range?(txn, filters[:from_date], filters[:to_date]) &&
        matches_query?(txn, filters[:query])
    end

    def matches_type_and_category?(txn, type, category)
      return false if type && txn.type != type.to_sym
      return false if category && txn.category.downcase != category.to_s.strip.downcase

      true
    end

    def matches_date_range?(txn, from_date, to_date)
      return false if from_date && txn.date < from_date.to_s
      return false if to_date && txn.date > to_date.to_s

      true
    end

    def matches_query?(txn, query)
      return true if query.nil? || query.to_s.strip.empty?

      needle = query.to_s.strip.downcase
      txn.description.downcase.include?(needle) || txn.category.downcase.include?(needle)
    end

    def category_breakdown(transactions)
      transactions.each_with_object(Hash.new(0)) do |txn, totals|
        totals[txn.category] += txn.signed_cents
      end
    end
  end
end
