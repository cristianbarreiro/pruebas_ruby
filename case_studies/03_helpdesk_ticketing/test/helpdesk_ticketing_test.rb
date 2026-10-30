# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/helpdesk_ticketing"

class HelpdeskTicketingTest < Minitest::Test
  def setup
    @service = HelpdeskTicketing::TicketService.new
    @tck1 = @service.create_ticket(
      title: "Fallo VPN", description: "No conecta al gateway",
      requester: "ana@ejemplo.local", priority: :high, category: "redes",
      created_at: "2026-02-01T10:00:00Z"
    )
    @tck2 = @service.create_ticket(
      title: "Instalar editor", description: "Falta paquete en estación",
      requester: "luis@ejemplo.local", priority: :low, category: "software",
      created_at: "2026-02-01T11:00:00Z"
    )
  end

  def test_transition_policy_allows_valid_paths_and_rejects_invalid_ones
    policy = HelpdeskTicketing::TransitionPolicy.new

    assert policy.can_transition?(:open, :in_progress)
    assert policy.can_transition?(:in_progress, :pending)
    assert policy.can_transition?(:pending, :resolved)
    assert policy.can_transition?(:resolved, :open)
    refute policy.can_transition?(:open, :resolved)
    assert_raises(HelpdeskTicketing::Errors::InvalidTransitionError) do
      policy.validate!(:open, :resolved)
    end
  end

  def test_ticket_validates_priority_and_required_fields
    assert_raises(HelpdeskTicketing::Errors::ValidationError) do
      @service.create_ticket(
        title: "", description: "Detalle", requester: "ana@ejemplo.local"
      )
    end
    assert_raises(HelpdeskTicketing::Errors::ValidationError) do
      @service.create_ticket(
        title: "Aviso", description: "Detalle",
        requester: "ana@ejemplo.local", priority: :urgent
      )
    end
  end

  def test_ticket_lifecycle_records_history_and_resolution_seconds
    @service.assign_ticket(@tck1.id, "carlos.vega")
    @service.transition_status(@tck1.id, :in_progress, timestamp: "2026-02-01T10:05:00Z", note: "Tomado")
    @service.transition_status(@tck1.id, :resolved, timestamp: "2026-02-01T10:20:00Z", note: "Solucionado")

    assert_predicate @tck1, :resolved?
    assert_in_delta(1200.0, @tck1.resolution_seconds)
    assert_equal 2, @tck1.history.size

    @service.transition_status(@tck1.id, :open, timestamp: "2026-02-01T10:30:00Z", note: "Reabierto")

    assert_nil @tck1.resolution_seconds
    assert_equal :open, @tck1.status
  end

  def test_search_and_stats_aggregation
    @service.assign_ticket(@tck1.id, "carlos.vega")
    @service.transition_status(@tck1.id, :in_progress, timestamp: "2026-02-01T10:05:00Z")
    @service.transition_status(@tck1.id, :resolved, timestamp: "2026-02-01T10:15:00Z")

    assert_equal ["TCK-001"], @service.search(status: :resolved, priority: :high).map(&:id)
    assert_equal ["TCK-002"], @service.search(query: "editor").map(&:id)

    rep = @service.stats

    assert_equal 2, rep[:total]
    assert_equal({ resolved: 1, open: 1 }, rep[:by_status])
    assert_in_delta(900.0, rep[:average_resolution_seconds])
  end

  def test_json_repository_persists_tickets_and_history_atomically
    Dir.mktmpdir do |dir|
      db_file = File.join(dir, "tickets.json")
      repo = HelpdeskTicketing::JsonRepository.new(db_file)
      srv = HelpdeskTicketing::TicketService.new(repository: repo)
      tck = srv.create_ticket(
        title: "Corte fibra", description: "Enlace caído",
        requester: "ops@ejemplo.local", priority: :critical
      )
      srv.transition_status(tck.id, :in_progress, note: "Escalado a proveedor")

      reloaded = HelpdeskTicketing::TicketService.new(repository: repo).find_ticket(tck.id)

      assert_equal :in_progress, reloaded.status
      assert_equal "Escalado a proveedor", reloaded.history.first[:note]
    end
  end

  def test_cli_commands_and_invalid_transition_error_output
    Dir.mktmpdir do |dir|
      db_file = File.join(dir, "cli_tickets.json")
      out = StringIO.new
      err = StringIO.new
      cli = HelpdeskTicketing::CLI.new(out: out, err: err, db_path: db_file)

      assert_equal 0, cli.run(["create", "Error DNS", "No resuelve", "ana@ejemplo.local", "high", "redes"])
      assert_equal 0, cli.run(["assign", "TCK-001", "lucia.rojas"])
      assert_equal 1, cli.run(["transition", "TCK-001", "resolved", "Intento directo"])
      assert_equal 0, cli.run(["transition", "TCK-001", "in_progress", "En revisión"])
      assert_includes out.string, "asignado a lucia.rojas"
      assert_includes err.string, "Error: Transición inválida"
    end
  end
end
