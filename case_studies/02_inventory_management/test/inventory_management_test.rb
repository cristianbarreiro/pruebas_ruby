# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/inventory_management"

class InventoryManagementTest < Minitest::Test
  def setup
    @service = InventoryManagement::InventoryService.new
    @service.create_product(
      sku: "kbd-01", name: "Teclado Mecánico", category: "Perifericos",
      price_cents: 8500, stock: 10, min_stock: 4
    )
    @service.create_product(
      sku: "cab-02", name: "Cable USB-C", category: "Conectividad",
      price_cents: 1200, stock: 2, min_stock: 5
    )
  end

  def test_product_normalizes_attributes_and_detects_low_stock
    prod = @service.find_product("KBD-01")

    assert_equal "KBD-01", prod.sku
    assert_equal "perifericos", prod.category
    assert_equal 85_000, prod.inventory_value_cents
    refute_predicate prod, :low_stock?
    assert_predicate @service.find_product("CAB-02"), :low_stock?
  end

  def test_product_rejects_invalid_price_and_negative_stock
    assert_raises(InventoryManagement::Errors::ValidationError) do
      InventoryManagement::Product.new(
        sku: "BAD-1", name: "Item", category: "Cat", price_cents: 0, stock: 1
      )
    end
    assert_raises(InventoryManagement::Errors::ValidationError) do
      InventoryManagement::Product.new(
        sku: "BAD-2", name: "Item", category: "Cat", price_cents: 500, stock: -1
      )
    end
  end

  def test_stock_movement_validates_type_quantity_and_reason
    mov = InventoryManagement::StockMovement.new(
      sku: "kbd-01", type: :in, quantity: 5, reason: "Reposición"
    )

    assert_predicate mov, :entry?
    assert_equal 5, mov.signed_delta

    assert_raises(InventoryManagement::Errors::ValidationError) do
      InventoryManagement::StockMovement.new(type: :invalid, quantity: 3, reason: "Ajuste")
    end
    assert_raises(InventoryManagement::Errors::ValidationError) do
      InventoryManagement::StockMovement.new(type: :out, quantity: 0, reason: "Ajuste")
    end
  end

  def test_service_prevents_duplicate_sku_and_handles_missing_product
    assert_raises(InventoryManagement::Errors::DuplicateSkuError) do
      @service.create_product(
        sku: "KBD-01", name: "Otro", category: "Cat", price_cents: 1000
      )
    end
    assert_raises(InventoryManagement::Errors::NotFoundError) do
      @service.find_product("NO-EXISTE")
    end
  end

  def test_record_entry_and_exit_update_stock_and_prevent_negative_balance
    @service.record_entry(sku: "KBD-01", quantity: 5, reason: "Compra lote")
    @service.record_exit(sku: "KBD-01", quantity: 12, reason: "Venta mayorista")

    assert_equal 3, @service.find_product("KBD-01").stock
    assert_equal 2, @service.movements_for("KBD-01").size

    assert_raises(InventoryManagement::Errors::InsufficientStockError) do
      @service.record_exit(sku: "KBD-01", quantity: 4, reason: "Exceso")
    end
    assert_equal 3, @service.find_product("KBD-01").stock
  end

  def test_search_low_stock_and_valuation_report
    assert_equal 1, @service.search("mecánico").size
    assert_equal 1, @service.search(category: "conectividad").size
    assert_equal ["CAB-02"], @service.low_stock_products.map(&:sku)

    report = @service.valuation_report

    assert_equal 2, report[:total_skus]
    assert_equal 12, report[:total_units]
    assert_equal 87_400, report[:total_value_cents]
  end

  def test_update_and_delete_product
    updated = @service.update_product("KBD-01", price_cents: 9000, min_stock: 15)

    assert_equal 9000, updated.price_cents
    assert_predicate updated, :low_stock?

    deleted = @service.delete_product("KBD-01")

    assert_equal "KBD-01", deleted.sku
    assert_equal 1, @service.all_products.size
  end

  def test_json_repository_persists_products_and_movements_atomically
    Dir.mktmpdir do |dir|
      db_file = File.join(dir, "inventory.json")
      repo = InventoryManagement::JsonRepository.new(db_file)
      srv = InventoryManagement::InventoryService.new(repository: repo)
      srv.create_product(sku: "SSD-1", name: "SSD 1TB", category: "Storage", price_cents: 7000, stock: 5)
      srv.record_entry(sku: "SSD-1", quantity: 3, reason: "Ingreso")

      reloaded = InventoryManagement::InventoryService.new(repository: repo)

      assert_equal 8, reloaded.find_product("SSD-1").stock
      assert_equal 1, reloaded.movements_for("SSD-1").size
    end
  end

  def test_cli_commands_with_injected_streams_and_temp_db
    Dir.mktmpdir do |dir|
      db_file = File.join(dir, "cli_inv.json")
      out = StringIO.new
      cli = InventoryManagement::CLI.new(input: StringIO.new, output: out, db_path: db_file)

      assert_equal 0, cli.run(["add", "MON-1", "Monitor 24", "monitores", "15000", "4", "2"])
      assert_equal 0, cli.run(["stock-out", "MON-1", "3", "Venta cliente"])
      assert_equal 0, cli.run(["low-stock"])
      assert_equal 1, cli.run(["stock-out", "MON-1", "5", "Sin stock"])
      assert_includes out.string, "[LOW STOCK]"
      assert_includes out.string, "Error: Stock insuficiente"
    end
  end
end
