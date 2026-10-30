# frozen_string_literal: true

require "test_helper"
require "stringio"
require_relative "../lib/expense_tracker"

module ExpenseTracker
  class ExpenseTrackerTest < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir("expense_tracker_test")
      @storage_path = File.join(@tmpdir, "expenses.json")
      @store = JsonStore.new(@storage_path)
      @ledger = Ledger.new(@store)
    end

    def teardown
      FileUtils.remove_entry(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
    end

    def test_creates_valid_income_and_expense_transactions
      income = @ledger.record(type: :income, amount: "1200.50", category: "Salario", description: "Pago",
                              date: "2026-10-01")
      expense = @ledger.record(type: :expense, amount: 45.25, category: "Comida", description: "Almuerzo",
                               date: "2026-10-02")

      assert_equal 120_050, income.amount_cents
      assert_predicate income, :income?
      assert_equal 4525, expense.amount_cents
      assert_predicate expense, :expense?
    end

    def test_validates_invalid_transaction_inputs
      assert_raises(ArgumentError) do
        Transaction.build(type: :invalid, amount: 10, category: "Ocio", description: "Cine")
      end
      assert_raises(ArgumentError) do
        Transaction.build(type: :expense, amount: -5, category: "Ocio", description: "Cine")
      end
      assert_raises(ArgumentError) do
        Transaction.build(type: :expense, amount: 10, category: " ", description: "Cine")
      end
      assert_raises(ArgumentError) do
        Transaction.build(type: :expense, amount: 10, category: "Ocio", description: "Cine", date: "fecha-mala")
      end
    end

    def test_filters_and_calculates_summary_accurately
      @ledger.record(type: :income, amount: 1000, category: "Salario", description: "Mes", date: "2026-10-01")
      @ledger.record(type: :expense, amount: 250.75, category: "Hogar", description: "Luz eléctrica",
                     date: "2026-10-05")
      @ledger.record(type: :expense, amount: 49.25, category: "Hogar", description: "Agua potable", date: "2026-10-10")

      hogar = @ledger.list(category: "hogar", from_date: "2026-10-06")
      summary = @ledger.summarize

      assert_equal 1, hogar.size
      assert_equal "Agua potable", hogar.first.description
      assert_equal 100_000, summary.income_cents
      assert_equal 30_000, summary.expense_cents
      assert_equal 70_000, summary.balance_cents
      assert_equal(-30_000, summary.by_category["Hogar"])
    end

    def test_handles_corrupted_json_and_missing_id_on_delete
      File.write(@storage_path, "{corrupt_json")

      assert_raises(DataCorruptError) { @store.load_all }

      File.write(@storage_path, "[]")
      assert_raises(NotFoundError) { @ledger.delete("inexistente") }
    end

    def test_exports_transactions_to_csv
      @ledger.record(type: :expense, amount: 19.99, category: "Libros", description: "Guía Ruby", date: "2026-10-15")
      csv_path = File.join(@tmpdir, "export.csv")

      CsvExporter.export(@ledger.list, csv_path)
      rows = CSV.read(csv_path, headers: true)

      assert_equal 1, rows.size
      assert_equal "Libros", rows.first["category"]
      assert_equal "19.99", rows.first["amount"]
    end

    def test_cli_end_to_end_workflow
      out = StringIO.new
      err = StringIO.new
      cli = CLI.new(out: out, err: err, default_storage: @storage_path)

      code_add = cli.call(%w[add --type income --amount 500 --category Bono --desc Proyecto --date 2026-10-12])
      code_sum = cli.call(%w[summary])
      code_bad = cli.call(%w[add --type expense --amount -10 --category Error --desc Fallo])

      assert_equal 0, code_add
      assert_equal 0, code_sum
      assert_includes out.string, "Balance:      $500.00"
      assert_equal 1, code_bad
      assert_includes err.string, "Error:"
    end
  end
end
