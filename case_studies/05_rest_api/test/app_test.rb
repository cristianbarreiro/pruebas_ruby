# frozen_string_literal: true

ENV["APP_ENV"] = "test"

require "json"
require "minitest/autorun"
require "rack/test"
require "tmpdir"
require_relative "../lib/rest_api"

class RestApiAppTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    @tmp_dir = Dir.mktmpdir("rest_api_test")
    storage_file = File.join(@tmp_dir, "tickets.json")
    repo = RestApi::TicketRepository.new(storage_path: storage_file)
    RestApi::App.set :ticket_service, RestApi::TicketService.new(repository: repo)
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def app
    RestApi::App
  end

  def test_health_endpoint_succeeds
    get "/health"

    assert_equal 200, last_response.status
    assert_includes last_response.content_type, "application/json"
    assert_equal "ok", parsed_body["status"]
  end

  def test_post_tickets_creates_new_ticket
    post_json "/tickets", title: "Fallo en login", description: "No carga OAuth", priority: "high"

    assert_equal 201, last_response.status
    data = parsed_body["data"]

    refute_nil data["id"]
    assert_equal "Fallo en login", data["title"]
    assert_equal "open", data["status"]
    assert_equal "high", data["priority"]
  end

  def test_get_tickets_and_get_by_id_succeed
    created = create_sample_ticket(title: "Error de red", priority: "critical")

    get "/tickets", priority: "critical"

    assert_equal 200, last_response.status
    assert_equal 1, parsed_body["count"]

    get "/tickets/#{created["id"]}"

    assert_equal 200, last_response.status
    assert_equal "Error de red", parsed_body.dig("data", "title")
  end

  def test_patch_ticket_updates_fields
    created = create_sample_ticket

    patch_json "/tickets/#{created["id"]}", status: "resolved", priority: "low"

    assert_equal 200, last_response.status
    assert_equal "resolved", parsed_body.dig("data", "status")
    assert_equal "low", parsed_body.dig("data", "priority")
  end

  def test_delete_ticket_removes_record
    created = create_sample_ticket

    delete "/tickets/#{created["id"]}"

    assert_equal 204, last_response.status
    assert_empty last_response.body

    get "/tickets/#{created["id"]}"

    assert_equal 404, last_response.status
  end

  def test_rejects_malformed_or_empty_json_with_bad_request
    header "CONTENT_TYPE", "application/json"
    post "/tickets", "{invalid_json"

    assert_equal 400, last_response.status
    assert_equal "bad_request", parsed_body.dig("error", "code")

    post "/tickets", ""

    assert_equal 400, last_response.status
  end

  def test_returns_not_found_when_ticket_does_not_exist
    get "/tickets/inexistente-999"

    assert_equal 404, last_response.status
    assert_equal "not_found", parsed_body.dig("error", "code")

    delete "/tickets/inexistente-999"

    assert_equal 404, last_response.status
  end

  def test_returns_unprocessable_entity_when_validation_fails
    post_json "/tickets", title: "ab", description: "Título demasiado corto"

    assert_equal 422, last_response.status
    assert_equal "unprocessable_entity", parsed_body.dig("error", "code")

    post_json "/tickets", title: "Ticket válido", description: "Detalle", status: "invalid_state"

    assert_equal 422, last_response.status
  end

  private

  def create_sample_ticket(overrides = {})
    defaults = { title: "Soporte general", description: "Consulta sobre facturación", priority: "medium" }
    post_json "/tickets", defaults.merge(overrides)
    parsed_body["data"]
  end

  def post_json(uri, payload)
    header "CONTENT_TYPE", "application/json"
    post uri, JSON.generate(payload)
  end

  def patch_json(uri, payload)
    header "CONTENT_TYPE", "application/json"
    patch uri, JSON.generate(payload)
  end

  def parsed_body
    JSON.parse(last_response.body)
  end
end
