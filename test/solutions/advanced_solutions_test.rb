# frozen_string_literal: true

require "test_helper"
require "stringio"
require "tmpdir"

%w[
  01_immutable_query_builder
  02_notification_service_di
  03_shipping_strategy_factory
  04_streaming_log_aggregator
  05_thread_safe_worker_pool
  06_lookup_benchmark_analyzer
  07_tariff_rules_refactoring
  08_middleware_pipeline
].each { |solution| TestSupport.require_solution("advanced/#{solution}") }

class AdvancedSolutionsTest < Minitest::Test
  # ===========================================================================
  # 01: ImmutableQueryBuilder
  # ===========================================================================
  def sample_users
    [
      { id: 1, name: "Ana", role: "admin", score: 95 },
      { id: 2, name: "Luis", role: "editor", score: 82 },
      { id: 3, name: "Marta", role: "admin", score: 88 },
      { id: 4, name: "Carlos", role: "admin", score: 88 },
      { id: 5, name: "Elena", role: "viewer", score: 70 }
    ]
  end

  def test_query_builder_immutability_and_filtering
    base = Solutions::Advanced::ImmutableQueryBuilder::QueryBuilder.new(sample_users)
    admins = base.where(role: "admin")
    high_admins = admins.where { |row| row[:score] >= 90 }

    assert_equal 5, base.execute[:meta][:total]
    assert_equal 3, admins.execute[:meta][:total]
    assert_equal(["Ana"], high_admins.to_a.map { |row| row[:name] })
  end

  def test_query_builder_multi_column_order_and_pagination
    builder_class = Solutions::Advanced::ImmutableQueryBuilder::QueryBuilder
    result = builder_class.new(sample_users)
                          .where(role: %w[admin editor])
                          .order_by(:score, :asc)
                          .order_by(:name, :desc)
                          .paginate(page: 1, per_page: 3)
                          .execute

    assert_equal(%w[Luis Marta Carlos], result[:data].map { |row| row[:name] })
    assert_equal({ page: 1, per_page: 3, total: 4, total_pages: 2 }, result[:meta])
  end

  def test_query_builder_empty_and_validation_errors
    builder_class = Solutions::Advanced::ImmutableQueryBuilder::QueryBuilder
    empty_res = builder_class.new([]).execute
    base = builder_class.new(sample_users)

    assert_empty empty_res[:data]
    assert_equal 0, empty_res[:meta][:total_pages]
    assert_raises(ArgumentError) { base.where }
    assert_raises(ArgumentError) { base.order_by(:score, :sideways) }
    assert_raises(ArgumentError) { base.paginate(page: 0, per_page: 5) }
  end

  # ===========================================================================
  # 02: NotificationServiceDi
  # ===========================================================================
  def test_notification_dispatcher_primary_and_fallback
    mod = Solutions::Advanced::NotificationServiceDi
    sms_channel = mod::MemoryChannel.new(:sms)
    dispatcher = mod::NotificationDispatcher.new(
      channels: { email: mod::FailingChannel.new("SMTP timeout"), sms: sms_channel },
      clock: mod::FakeClock.new(1_000.0),
      logger: mod::MemoryLogger.new
    )
    result = dispatcher.dispatch(recipient: "ana@test.com", message: "Hola", channel: :email, fallback: :sms)

    assert_equal :delivered, result[:status]
    assert_equal :sms, result[:channel]
    assert result[:fallback_used]
    assert_equal 1, sms_channel.deliveries.size
  end

  def test_notification_dispatcher_rate_limiting_and_clock_window
    mod = Solutions::Advanced::NotificationServiceDi
    clock = mod::FakeClock.new(5_000.0)
    dispatcher = mod::NotificationDispatcher.new(
      channels: { push: mod::MemoryChannel.new(:push) },
      clock: clock,
      logger: mod::MemoryLogger.new,
      rate_limit: 2,
      window_seconds: 30
    )
    2.times { dispatcher.dispatch(recipient: "usr-1", message: "Ping", channel: :push) }

    assert_raises(mod::RateLimitExceededError) do
      dispatcher.dispatch(recipient: "usr-1", message: "Tercero bloqueado", channel: :push)
    end

    clock.advance(31.0)
    res = dispatcher.dispatch(recipient: "usr-1", message: "Permitido tras ventana", channel: :push)

    assert_equal :delivered, res[:status]
  end

  def test_notification_dispatcher_total_failure_and_invalid_input
    mod = Solutions::Advanced::NotificationServiceDi
    dispatcher = mod::NotificationDispatcher.new(
      channels: { email: mod::FailingChannel.new("Caído") }
    )

    assert_raises(mod::DeliveryError) do
      dispatcher.dispatch(recipient: "bob@test.com", message: "Alerta", channel: :email)
    end
    assert_raises(ArgumentError) do
      dispatcher.dispatch(recipient: "", message: "Alerta", channel: :email)
    end
    assert_raises(ArgumentError) do
      dispatcher.dispatch(recipient: "bob@test.com", message: "Alerta", channel: :unknown)
    end
  end

  # ===========================================================================
  # 03: ShippingStrategyFactory
  # ===========================================================================
  def test_shipping_strategies_and_factory_quotes
    mod = Solutions::Advanced::ShippingStrategyFactory
    std = mod::ShippingFactory.for("STANDARD").build_quote(id: "Q1", weight_kg: 10.0, distance_km: 600.0)
    exp = mod::ShippingFactory.for(:express).build_quote(id: "Q2", weight_kg: 25.0, distance_km: 1200.0)
    intl = mod::ShippingFactory.for(:international).build_quote(
      id: "Q3", weight_kg: 5.0, distance_km: 3000.0, declared_value: 100.0
    )

    assert_in_delta 47.5, std.cost, 0.001
    assert_equal 5, std.estimated_days
    assert_in_delta 231.5, exp.cost, 0.001
    assert_equal 2, exp.estimated_days
    assert_in_delta 310.0, intl.cost, 0.001
    assert_equal 9, intl.estimated_days
  end

  def test_shipment_repository_and_validation_errors
    mod = Solutions::Advanced::ShippingStrategyFactory
    repo = mod::ShipmentRepository.new
    quote = mod::ShippingFactory.for(:standard).build_quote(id: "Q-99", weight_kg: 4.0, distance_km: 0.0)
    repo.save(quote)

    assert_equal quote, repo.find("Q-99")
    assert_equal 1, repo.by_strategy(:standard).size
    assert_in_delta 10.0, repo.total_cost, 0.001
    assert_raises(ArgumentError) { mod::ShippingFactory.for(:teleport) }
    assert_raises(ArgumentError) { mod::ShippingFactory.for(:express).calculate(weight_kg: 60.0, distance_km: 10.0) }
    assert_raises(ArgumentError) { mod::ShippingFactory.for(:standard).calculate(weight_kg: 0, distance_km: 10.0) }
  end

  # ===========================================================================
  # 04: StreamingLogAggregator
  # ===========================================================================
  def test_streaming_log_aggregator_counts_and_malformed_tracking
    raw_logs = <<~LOGS
      [2026-05-10 10:00:01] INFO auth: Login exitoso
      [2026-05-10 10:00:02] WARN auth: Intento sospechoso
      linea corrupta 1
      [2026-05-10 10:00:03] ERROR billing: Tarjeta rechazada
      linea corrupta 2
      linea corrupta 3
    LOGS
    aggregator = Solutions::Advanced::StreamingLogAggregator::LogAggregator.new(max_samples: 2)
    report = aggregator.aggregate(StringIO.new(raw_logs))

    assert_equal 6, report[:total_lines]
    assert_equal 3, report[:valid_lines]
    assert_equal 3, report[:malformed_lines]
    assert_equal 2, report[:malformed_samples].size
    assert_equal({ "INFO" => 1, "WARN" => 1, "ERROR" => 1 }, report[:by_level])
    assert_equal({ "auth" => 2, "billing" => 1 }, report[:by_service])
  end

  def test_streaming_log_aggregator_lazy_and_file_support
    aggregator = Solutions::Advanced::StreamingLogAggregator::LogAggregator.new
    lines = [
      "[2026-05-10 10:00:01] INFO api: Request 1",
      "basura",
      "[2026-05-10 10:00:02] ERROR api: Request 2"
    ]
    lazy_stream = aggregator.lazy_entries(lines)

    assert_instance_of Enumerator::Lazy, lazy_stream
    assert_equal "INFO", lazy_stream.first.level

    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "sample.log")
      File.write(file_path, lines.join("\n"))
      filtered = aggregator.aggregate_file(file_path, level_filter: "ERROR")

      assert_equal 1, filtered[:valid_lines]
      assert_equal 1, filtered[:malformed_lines]
    end
  end

  # ===========================================================================
  # 05: ThreadSafeWorkerPool
  # ===========================================================================
  def test_worker_pool_concurrent_execution_and_error_isolation
    pool = Solutions::Advanced::ThreadSafeWorkerPool::WorkerPool.new(size: 3)
    15.times do |idx|
      pool.schedule("job-#{idx}") { (idx % 5).zero? ? raise(ArgumentError, "Fallo") : idx * 2 }
    end
    results = pool.shutdown

    assert_equal 15, results.size
    assert_equal({ total: 15, succeeded: 12, failed: 3 }, pool.stats)
    assert_instance_of ArgumentError, results[0][:error]
    assert_equal 2, results[1][:value]
  end

  def test_worker_pool_validation_and_closed_state
    pool_class = Solutions::Advanced::ThreadSafeWorkerPool::WorkerPool

    assert_raises(ArgumentError) { pool_class.new(size: 0) }

    pool = pool_class.new(size: 2)

    assert_raises(ArgumentError) { pool.schedule("invalid") }
    pool.shutdown

    assert_raises(RuntimeError) { pool.schedule("after-close") { 42 } }
  end

  # ===========================================================================
  # 06: LookupBenchmarkAnalyzer
  # ===========================================================================
  def test_lookup_benchmark_analyzer_metrics_and_validation
    analyzer_class = Solutions::Advanced::LookupBenchmarkAnalyzer::BenchmarkAnalyzer
    report = analyzer_class.compare(collection_size: 800, lookups_count: 300, seed: 99)
    hits_per_type = report[:metrics].values.map { |entry| entry[:hits] }.uniq

    assert_equal 800, report[:collection_size]
    assert_includes %i[array set hash], report[:fastest]
    assert_operator report[:speedup_ratio], :>=, 1.0
    assert_equal 1, hits_per_type.size
    assert_raises(ArgumentError) { analyzer_class.compare(collection_size: 0, lookups_count: 10) }
  end

  # ===========================================================================
  # 07: TariffRulesRefactoring
  # ===========================================================================
  def test_tariff_engine_residential_and_commercial_rules
    engine = Solutions::Advanced::TariffRulesRefactoring::TariffEngine.new
    res_bill = engine.calculate(
      customer_type: :residential, kwh: 300, peak_ratio: 0.5, green_certified: true, social_tariff: false
    )
    social_bill = engine.calculate(
      customer_type: :residential, kwh: 100, peak_ratio: 0.2, green_certified: false, social_tariff: true
    )

    assert_in_delta 45.9, res_bill[:total], 0.001
    assert_equal(%i[residential_base peak_surcharge green_discount], res_bill[:breakdown].map { |row| row[:rule] })
    assert_in_delta 9.0, social_bill[:total], 0.001
    assert_equal(%i[residential_base social_discount], social_bill[:breakdown].map { |row| row[:rule] })
  end

  def test_tariff_engine_zero_consumption_and_validation
    engine = Solutions::Advanced::TariffRulesRefactoring::TariffEngine.new
    zero_bill = engine.calculate(customer_type: :commercial, kwh: 0, peak_ratio: 0.0)

    assert_in_delta 0.0, zero_bill[:total], 0.001
    assert_empty zero_bill[:breakdown]
    assert_raises(ArgumentError) { engine.calculate(customer_type: :industrial, kwh: 100) }
    assert_raises(ArgumentError) { engine.calculate(customer_type: :residential, kwh: -5) }
    assert_raises(ArgumentError) { engine.calculate(customer_type: :residential, kwh: 50, peak_ratio: 1.5) }
  end

  # ===========================================================================
  # 08: MiddlewarePipeline
  # ===========================================================================
  def build_sample_pipeline
    mod = Solutions::Advanced::MiddlewarePipeline
    mod::Pipeline.new
                 .use(mod::AuthMiddleware.new("valid-tok" => "usr-7"))
                 .use(mod::ValidationMiddleware.new(%i[item qty]))
                 .use(mod::EnrichmentMiddleware.new(request_id: "req-77"))
                 .use(mod::HandlerMiddleware.new)
  end

  def test_middleware_pipeline_full_execution_and_immutability
    initial_ctx = Solutions::Advanced::MiddlewarePipeline::Context.build(
      token: "valid-tok", payload: { item: "Libro", qty: 1 }
    )
    final_ctx = build_sample_pipeline.call(initial_ctx)

    assert_empty initial_ctx.trace
    refute_predicate final_ctx, :halted?
    assert_equal 200, final_ctx.response[:status]
    assert_equal "usr-7", final_ctx.metadata[:user_id]
    assert_equal %w[auth validation enrichment handler], final_ctx.trace
  end

  def test_middleware_pipeline_short_circuit_on_auth_and_validation
    pipeline = build_sample_pipeline
    unauth = pipeline.call(token: "bad", payload: { item: "Libro", qty: 1 })
    invalid = pipeline.call(token: "valid-tok", payload: { item: "", qty: 1 })

    assert_predicate unauth, :halted?
    assert_equal 401, unauth.response[:status]
    assert_equal %w[auth], unauth.trace
    assert_predicate invalid, :halted?
    assert_equal 422, invalid.response[:status]
    assert_equal %w[auth validation], invalid.trace
  end
end
