# frozen_string_literal: true

require "test_helper"
require "stringio"

TestSupport.require_solution("beginner/01_temperature_converter")
TestSupport.require_solution("beginner/02_password_validator")
TestSupport.require_solution("beginner/03_text_normalizer")
TestSupport.require_solution("beginner/04_shopping_cart_summary")
TestSupport.require_solution("beginner/05_product_catalog_search")
TestSupport.require_solution("beginner/06_collection_statistics")
TestSupport.require_solution("beginner/07_console_quiz_prompt")
TestSupport.require_solution("beginner/08_invoice_line_calculator")
TestSupport.require_solution("beginner/09_number_series_generator")
TestSupport.require_solution("beginner/10_key_value_file_store")

class BeginnerSolutionsTest < Minitest::Test
  TempConverter = Solutions::Beginner::TemperatureConverter
  PwdValidator = Solutions::Beginner::PasswordValidator
  Normalizer = Solutions::Beginner::TextNormalizer
  CartSummary = Solutions::Beginner::ShoppingCartSummary
  CatalogSearch = Solutions::Beginner::ProductCatalogSearch
  Stats = Solutions::Beginner::CollectionStatistics
  QuizPrompt = Solutions::Beginner::ConsoleQuizPrompt
  InvoiceCalc = Solutions::Beginner::InvoiceLineCalculator
  SeriesGen = Solutions::Beginner::NumberSeriesGenerator
  KvStore = Solutions::Beginner::KeyValueFileStore

  def test_temperature_converter_standard_conversions
    assert_in_delta 32.0, TempConverter.convert(0, from: :celsius, to: :fahrenheit)
    assert_in_delta 373.15, TempConverter.convert(100, from: :celsius, to: :kelvin)
    assert_in_delta 37.0, TempConverter.convert(98.6, from: :fahrenheit, to: :celsius)
    assert_in_delta(-273.15, TempConverter.convert(0, from: :kelvin, to: :celsius))
    assert_in_delta(-40.0, TempConverter.convert(-40, from: :celsius, to: :fahrenheit))
    assert_in_delta 25.5, TempConverter.convert(25.5, from: :celsius, to: :celsius)
  end

  def test_temperature_converter_errors_and_absolute_zero
    assert_in_delta 0.0, TempConverter.convert(-273.15, from: :celsius, to: :kelvin)
    assert_in_delta 0.0, TempConverter.convert(-459.67, from: :fahrenheit, to: :kelvin)
    assert_raises(ArgumentError) { TempConverter.convert(-273.16, from: :celsius, to: :kelvin) }
    assert_raises(ArgumentError) { TempConverter.convert(-0.01, from: :kelvin, to: :celsius) }
    assert_raises(ArgumentError) { TempConverter.convert(10, from: :rankine, to: :celsius) }
    assert_raises(ArgumentError) { TempConverter.convert("100", from: :celsius, to: :kelvin) }
  end

  def test_password_validator_accepts_strong_password
    result = PwdValidator.validate("Segura#2026")

    assert result[:valid]
    assert_empty result[:errors]
  end

  def test_password_validator_collects_multiple_errors
    short_result = PwdValidator.validate("abc")

    refute short_result[:valid]
    assert_equal 4, short_result[:errors].size

    spaced_result = PwdValidator.validate("Segura# 2026")

    refute spaced_result[:valid]
    assert_equal 1, spaced_result[:errors].size
    assert_raises(ArgumentError) { PwdValidator.validate(nil) }
  end

  def test_text_normalizer_slugify_and_word_count
    slug = Normalizer.slugify("¡Programación en Ruby: Guía Rápida 2026!")

    assert_equal "programacion-en-ruby-guia-rapida-2026", slug
    assert_equal "", Normalizer.slugify(" --- !!! ")

    counts = Normalizer.word_count("Ruby es simple, Ruby es expresivo.")

    assert_equal({ "ruby" => 2, "es" => 2, "simple" => 1, "expresivo" => 1 }, counts)
    assert_empty Normalizer.word_count("...")
  end

  def test_text_normalizer_titleize_and_validation
    title = Normalizer.titleize("de la tierra a la luna en cohete")

    assert_equal "De la Tierra a la Luna en Cohete", title
    assert_equal "Árboles y Ñandúes", Normalizer.titleize("ÁRBOLES Y ÑANDÚES")
    assert_raises(ArgumentError) { Normalizer.slugify(123) }
    assert_raises(ArgumentError) { Normalizer.word_count(nil) }
    assert_raises(ArgumentError) { Normalizer.titleize(:symbol) }
  end

  def test_shopping_cart_summary_calculations
    items = [
      { name: "Teclado Mecánico", unit_price_cents: 50_000, quantity: 1 },
      { name: "Cable USB-C", unit_price_cents: 10_000, quantity: 2 }
    ]
    summary = CartSummary.summarize(items, discount_rate: 0.10, tax_rate: 0.19)
    expected = {
      subtotal_cents: 70_000, discount_cents: 7_000,
      tax_cents: 11_970, total_cents: 74_970, line_count: 2
    }

    assert_equal expected, summary
  end

  def test_shopping_cart_summary_empty_and_invalid_inputs
    empty_summary = CartSummary.summarize([])

    assert_equal 0, empty_summary[:total_cents]
    assert_equal 0, empty_summary[:line_count]
    assert_raises(ArgumentError) { CartSummary.summarize([{ name: "X", unit_price_cents: 100, quantity: 0 }]) }
    assert_raises(ArgumentError) { CartSummary.summarize([{ name: "X", unit_price_cents: -1, quantity: 1 }]) }
    assert_raises(ArgumentError) { CartSummary.summarize([], discount_rate: 1.5) }
    assert_raises(ArgumentError) { CartSummary.summarize("invalid") }
  end

  def test_product_catalog_search_filters_and_sorting
    catalog = sample_catalog
    results = CatalogSearch.search(catalog, category: :electronics, max_price: 250, in_stock_only: true)

    assert_equal(["Teclado Mecánico", "Monitor 27\""], results.map { |item| item[:name] })

    by_query = CatalogSearch.search(catalog, query: "  mouse ")

    assert_equal(["Mouse Inalámbrico"], by_query.map { |item| item[:name] })

    ties = CatalogSearch.search(catalog, min_price: 250)

    assert_equal(["Monitor 27\"", "Silla Ergonómica"], ties.map { |item| item[:name] })
  end

  def test_product_catalog_search_validation
    assert_raises(ArgumentError) { CatalogSearch.search(nil) }
    assert_raises(ArgumentError) { CatalogSearch.search([], min_price: 200, max_price: 100) }
    assert_raises(ArgumentError) { CatalogSearch.search([], min_price: -5) }
  end

  def test_collection_statistics_odd_and_even_collections
    odd_stats = Stats.analyze([10, 20, 20, 30, 40])

    assert_equal 5, odd_stats[:count]
    assert_in_delta 24.0, odd_stats[:mean]
    assert_in_delta 20.0, odd_stats[:median]
    assert_equal [20], odd_stats[:modes]
    assert_equal 30, odd_stats[:range]
  end

  def test_collection_statistics_even_median_and_errors
    even_stats = Stats.analyze([4, 1, 3, 2])

    assert_in_delta 2.5, even_stats[:median]
    assert_equal [1, 2, 3, 4], even_stats[:modes]
    assert_equal 1, even_stats[:min]
    assert_equal 4, even_stats[:max]
    assert_raises(ArgumentError) { Stats.analyze([]) }
    assert_raises(ArgumentError) { Stats.analyze([1, "2", 3]) }
  end

  def test_console_quiz_prompt_succeeds_after_retry
    input = StringIO.new("tal vez\n  SI \n")
    output = StringIO.new
    answer = QuizPrompt.ask_until_valid(
      prompt: "¿Continuar?", valid_options: %w[si no], input: input, output: output, max_attempts: 3
    )

    assert_equal "si", answer
    assert_includes output.string, "Opción inválida"
  end

  def test_console_quiz_prompt_eof_and_exhausted_attempts
    out = StringIO.new
    assert_raises(ArgumentError) do
      QuizPrompt.ask_until_valid(prompt: "¿?", valid_options: %w[a b], input: StringIO.new(""), output: out)
    end
    assert_raises(ArgumentError) do
      QuizPrompt.ask_until_valid(
        prompt: "¿?", valid_options: %w[a b], input: StringIO.new("x\ny\n"), output: out, max_attempts: 2
      )
    end
    assert_raises(ArgumentError) { QuizPrompt.ask_until_valid(prompt: "", valid_options: %w[a]) }
  end

  def test_invoice_line_calculator_computes_immutable_result
    line = InvoiceCalc.calculate_line(
      "Licencia Pro", 2, unit_price_cents: 10_000, discount_percent: 10, tax_percent: 19
    )

    assert_equal 20_000, line.gross_cents
    assert_equal 2_000, line.discount_cents
    assert_equal 18_000, line.net_cents
    assert_equal 3_420, line.tax_cents
    assert_equal 21_420, line.total_cents
    assert_predicate line, :frozen?
  end

  def test_invoice_line_calculator_validation
    assert_raises(ArgumentError) { InvoiceCalc.calculate_line("  ", 1, unit_price_cents: 100) }
    assert_raises(ArgumentError) { InvoiceCalc.calculate_line("Item", 0, unit_price_cents: 100) }
    assert_raises(ArgumentError) { InvoiceCalc.calculate_line("Item", 1, unit_price_cents: -10) }
    assert_raises(ArgumentError) { InvoiceCalc.calculate_line("Item", 1, unit_price_cents: 100, discount_percent: 120) }
  end

  def test_number_series_generator_methods
    assert_equal %w[1 2 Fizz 4 Buzz Fizz], SeriesGen.fizz_buzz(6)
    assert_equal %w[1 Par Tres Par 5 ParTres], SeriesGen.fizz_buzz(6, rules: { 2 => "Par", 3 => "Tres" })
    assert_equal [6, 3, 10, 5, 16, 8, 4, 2, 1], SeriesGen.collatz_sequence(6)
    assert_equal [1], SeriesGen.collatz_sequence(1)
    assert_equal 33, SeriesGen.sum_of_multiples(10, factors: [3, 5])
  end

  def test_number_series_generator_validation
    assert_raises(ArgumentError) { SeriesGen.fizz_buzz(0) }
    assert_raises(ArgumentError) { SeriesGen.fizz_buzz(5, rules: {}) }
    assert_raises(ArgumentError) { SeriesGen.collatz_sequence(-3) }
    assert_raises(ArgumentError) { SeriesGen.sum_of_multiples(10, factors: []) }
  end

  def test_key_value_file_store_roundtrip_and_comments
    Dir.mktmpdir do |dir|
      path = File.join(dir, "settings.env")
      File.write(path, "# Comentario\n\nHOST = 127.0.0.1\nDSN = postgres://db?pool=5&ssl=true\nEMPTY=\n")
      loaded = KvStore.load_file(path)

      assert_equal({ "HOST" => "127.0.0.1", "DSN" => "postgres://db?pool=5&ssl=true", "EMPTY" => "" }, loaded)

      out_path = File.join(dir, "saved.env")

      assert_equal 2, KvStore.save_file(out_path, { "PORT" => 3000, "ENV" => "test" })
      assert_equal({ "PORT" => "3000", "ENV" => "test" }, KvStore.load_file(out_path))
    end
  end

  def test_key_value_file_store_errors
    Dir.mktmpdir do |dir|
      bad_path = File.join(dir, "bad.env")
      File.write(bad_path, "VALID=1\nMALFORMED_LINE\n")

      assert_raises(ArgumentError) { KvStore.load_file(bad_path) }

      empty_key_path = File.join(dir, "empty_key.env")
      File.write(empty_key_path, "=value_without_key\n")

      assert_raises(ArgumentError) { KvStore.load_file(empty_key_path) }
      assert_raises(ArgumentError) { KvStore.load_file(File.join(dir, "missing.env")) }
      assert_raises(ArgumentError) { KvStore.save_file(bad_path, { "BAD=KEY" => "val" }) }
    end
  end

  private

  def sample_catalog
    [
      { name: "Monitor 27\"", category: "electronics", price: 250.0, stock: 5 },
      { name: "Mouse Inalámbrico", category: "electronics", price: 25.0, stock: 0 },
      { name: "Teclado Mecánico", category: "electronics", price: 80.0, stock: 12 },
      { name: "Silla Ergonómica", category: "furniture", price: 250.0, stock: 3 }
    ]
  end
end
