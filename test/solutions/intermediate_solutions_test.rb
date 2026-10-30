# frozen_string_literal: true

require "test_helper"

%w[
  01_bank_account_domain
  02_order_pricing_engine
  03_auditable_searchable_mixins
  04_sales_csv_json_etl
  05_payment_gateway_errors
  06_json_file_repository
  07_subscription_billing_calculator
  08_binary_search_and_duplicates
  09_legacy_report_refactoring
  10_batch_file_organizer
].each do |solution_name|
  TestSupport.require_solution("intermediate/#{solution_name}")
end

class IntermediateSolutionsTest < Minitest::Test
  BankDomain = Solutions::Intermediate::BankAccountDomain
  PricingEngine = Solutions::Intermediate::OrderPricingEngine
  MixinsMod = Solutions::Intermediate::AuditableSearchableMixins
  SalesEtl = Solutions::Intermediate::SalesCsvJsonEtl
  GatewayMod = Solutions::Intermediate::PaymentGatewayErrors
  JsonRepoMod = Solutions::Intermediate::JsonFileRepository
  BillingCalc = Solutions::Intermediate::SubscriptionBillingCalculator
  AlgorithmsMod = Solutions::Intermediate::BinarySearchAndDuplicates
  ReportingMod = Solutions::Intermediate::LegacyReportRefactoring
  OrganizerMod = Solutions::Intermediate::BatchFileOrganizer

  def test_bank_account_deposit_withdraw_and_transfer
    alice = BankDomain::Account.new(owner: "Alice", opening_balance_cents: 10_000)
    bob = BankDomain::Account.new(owner: "Bob")
    alice.deposit(2_500, note: "Bonus")
    alice.transfer_to(bob, 4_000)

    assert_equal 8_500, alice.balance_cents
    assert_equal 4_000, bob.balance_cents
    assert_equal %i[opening deposit withdrawal], alice.movements.map(&:kind)
    assert_predicate alice.movements, :frozen?
  end

  def test_bank_account_guards_against_invalid_operations
    account = BankDomain::Account.new(owner: "Alice", opening_balance_cents: 1_000)

    assert_raises(BankDomain::InsufficientFundsError) { account.withdraw(2_000) }
    assert_raises(ArgumentError) { account.deposit(0) }
    assert_raises(ArgumentError) { account.deposit(12.5) }
    assert_raises(ArgumentError) { account.transfer_to(account, 500) }
    assert_equal 1_000, account.balance_cents
  end

  def test_order_pricing_with_percentage_discount_and_tax
    order = PricingEngine::Order.new(
      discount: PricingEngine::PercentageDiscount.new(10),
      tax_policy: PricingEngine::TaxPolicy.new(21)
    )
    order.add_item(sku: "BOOK-01", unit_price_cents: 2_500, quantity: 2)
    breakdown = order.pricing_breakdown

    assert_equal 5_000, breakdown.subtotal_cents
    assert_equal 500, breakdown.discount_cents
    assert_equal 4_500, breakdown.taxable_cents
    assert_equal 945, breakdown.tax_cents
    assert_equal 5_445, breakdown.total_cents
  end

  def test_order_pricing_with_threshold_discount_cap
    discount = PricingEngine::ThresholdDiscount.new(threshold_cents: 3_000, discount_cents: 5_000)
    order = PricingEngine::Order.new(discount: discount, tax_policy: PricingEngine::TaxPolicy.new(10))
    order.add_item(sku: "PEN", unit_price_cents: 3_500, quantity: 1)
    breakdown = order.pricing_breakdown

    assert_equal 3_500, breakdown.discount_cents
    assert_equal 0, breakdown.taxable_cents
    assert_equal 0, breakdown.total_cents
  end

  def test_auditable_and_comparable_catalog_items
    mouse = MixinsMod::CatalogItem.new(sku: "A1", name: "Mouse", price_cents: 2_500, category: :tech)
    keyboard = MixinsMod::CatalogItem.new(sku: "B2", name: "Keyboard", price_cents: 5_000, category: :tech)
    mouse.update_price(2_000)

    assert_operator mouse, :<, keyboard
    assert_nil(mouse <=> "not_an_item")
    assert_equal :price_updated, mouse.last_audit_action
    assert_equal 2, mouse.audit_log.size
  end

  def test_catalog_collection_enumerable_queries
    first = MixinsMod::CatalogItem.new(sku: "B2", name: "Key", price_cents: 4_000, category: :tech)
    second = MixinsMod::CatalogItem.new(sku: "A1", name: "Pad", price_cents: 1_500, category: :tech)
    inactive = MixinsMod::CatalogItem.new(sku: "C3", name: "Old", price_cents: 1_000, category: :tech, active: false)
    catalog = MixinsMod::CatalogCollection.new([first, second, inactive])

    assert_equal %w[A1 B2], catalog.by_category(:tech).map(&:sku)
    assert_equal %w[A1], catalog.price_range(min_cents: 1_000, max_cents: 2_000).map(&:sku)
    assert_equal 3, catalog.count
  end

  def test_sales_csv_json_etl_aggregates_and_captures_errors
    csv_input = <<~CSV
      id,customer,amount_cents,status
      1,Acme,5000,paid
      2,Globex,3000,pending
      3,Acme,bad_num,paid
      4,Acme,2500,paid
      5,,1000,paid
    CSV
    report = SalesEtl.process_csv(csv_input)

    assert_equal 5, report.total_rows
    assert_equal 2, report.valid_paid_rows
    assert_equal 1, report.skipped_unpaid_rows
    assert_equal({ "Acme" => 7_500 }, report.totals_by_customer)
    assert_equal 2, report.errors.size
  end

  def test_sales_csv_json_etl_exports_valid_json
    csv_input = "id,customer,amount_cents,status\n10,Initech,4200,paid\n"
    parsed = JSON.parse(SalesEtl.export_json(csv_input))

    assert_equal 4_200, parsed["grand_total_cents"]
    assert_equal({ "Initech" => 4_200 }, parsed["totals_by_customer"])
    assert_empty parsed["errors"]
  end

  def test_payment_processor_retries_transient_errors_only
    calls = 0
    gateway = build_stub_gateway do
      calls += 1
      raise GatewayMod::TransientGatewayError, "Timeout" if calls < 3

      "tx_ok"
    end
    processor = GatewayMod::PaymentProcessor.new(gateway: gateway, max_retries: 3)
    result = processor.charge(card_token: "tok_123", amount_cents: 2_000)

    assert_equal "tx_ok", result.transaction_id
    assert_equal 3, result.attempts
  end

  def test_payment_processor_does_not_retry_invalid_card
    calls = 0
    gateway = build_stub_gateway do
      calls += 1
      raise GatewayMod::InvalidCardError, "Declined"
    end
    processor = GatewayMod::PaymentProcessor.new(gateway: gateway, max_retries: 3)

    assert_raises(GatewayMod::InvalidCardError) do
      processor.charge(card_token: "tok_bad", amount_cents: 2_000)
    end
    assert_equal 1, calls
  end

  def test_json_file_repository_crud_and_atomic_persistence
    Dir.mktmpdir do |dir|
      repo = JsonRepoMod::Repository.new(File.join(dir, "users.json"))
      repo.save(id: "u1", name: "Ada")
      repo.save("id" => "u2", "name" => "Grace")

      assert_equal({ id: "u1", name: "Ada" }, repo.find("u1"))
      assert_equal 2, repo.all.size
      assert repo.delete("u1")
      refute repo.delete("u1")
      assert_nil repo.find("u1")
    end
  end

  def test_json_file_repository_raises_on_corrupted_json
    Dir.mktmpdir do |dir|
      path = File.join(dir, "broken.json")
      File.write(path, "{not_valid_json")
      repo = JsonRepoMod::Repository.new(path)

      assert_raises(JsonRepoMod::CorruptedStorageError) { repo.all }
    end
  end

  def test_subscription_billing_calculator_prorates_mid_month_and_leap_year
    april_quote = BillingCalc.calculate_change(
      current_price_cents: 3_000, new_price_cents: 6_000,
      billing_month_start: Date.new(2026, 4, 1), change_date: Date.new(2026, 4, 16)
    )
    leap_quote = BillingCalc.calculate_change(
      current_price_cents: 2_900, new_price_cents: 0,
      billing_month_start: Date.new(2024, 2, 1), change_date: Date.new(2024, 2, 15)
    )

    assert_equal 15, april_quote.remaining_days
    assert_equal 1_500, april_quote.net_amount_cents
    assert_equal 29, leap_quote.days_in_month
    assert_equal(-1_500, leap_quote.net_amount_cents)
  end

  def test_binary_search_duplicates_and_anagrams
    assert_equal 3, AlgorithmsMod.binary_search([10, 20, 30, 40, 50], 40)
    assert_nil AlgorithmsMod.binary_search([10, 20, 30], 99)
    assert_equal [1, 3], AlgorithmsMod.find_duplicates([3, 1, 4, 1, 5, 3, 1])
    assert_equal [%w[roma amor], %w[gato]], AlgorithmsMod.group_anagrams(%w[roma amor gato])
  end

  def test_legacy_report_refactoring_formatters
    entries = [
      ReportingMod::MetricEntry.new(service: "api", latency_ms: 100, success: true),
      ReportingMod::MetricEntry.new(service: "api", latency_ms: 200, success: false)
    ]
    text_out = ReportingMod::ReportGenerator.for_format(:text).generate(title: "API", entries: entries)
    json_out = JSON.parse(ReportingMod::ReportGenerator.for_format(:json).generate(title: "API", entries: entries))
    csv_out = ReportingMod::ReportGenerator.for_format(:csv).generate(title: "API", entries: entries)

    assert_includes text_out, "Avg Latency: 150.0ms"
    assert_in_delta 50.0, json_out["success_rate_percent"]
    assert_includes csv_out, "API,2,150.0,50.0"
    assert_raises(ArgumentError) { ReportingMod::ReportGenerator.for_format(:xml) }
  end

  def test_batch_file_organizer_dry_run_and_execution
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "photo.JPG"), "img")
      File.write(File.join(dir, "script.rb"), "code")
      File.write(File.join(dir, "archive.zip"), "zip")
      organizer = OrganizerMod::Organizer.new(dir)

      dry_manifest = organizer.call(dry_run: true)

      refute dry_manifest.any?(&:executed)
      assert_path_exists File.join(dir, "photo.JPG")

      real_manifest = organizer.call(dry_run: false)

      assert_equal %w[others images code], real_manifest.map(&:category)
      assert_path_exists File.join(dir, "images", "photo.JPG")
    end
  end

  private

  def build_stub_gateway(&block)
    gateway = Object.new
    gateway.define_singleton_method(:process) do |card_token:, amount_cents:|
      block.call(card_token, amount_cents)
    end
    gateway
  end
end
