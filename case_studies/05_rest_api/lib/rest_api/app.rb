# frozen_string_literal: true

require "json"
require "sinatra/base"
require_relative "ticket_service"

module RestApi
  # Aplicación HTTP REST JSON construida sobre Sinatra::Base.
  class App < Sinatra::Base
    configure do
      set :show_exceptions, false
      set :raise_errors, false
      set :dump_errors, false
      set :ticket_service, -> { TicketService.new }
    end

    before do
      content_type :json
    end

    get "/health" do
      json_response(200, { status: "ok", service: "tickets-rest-api" })
    end

    get "/tickets" do
      tickets = service.list_tickets(status: params["status"], priority: params["priority"])
      json_response(200, { data: tickets.map(&:to_h), count: tickets.size })
    end

    get "/tickets/:id" do
      ticket = service.find_ticket(params["id"])
      json_response(200, { data: ticket.to_h })
    end

    post "/tickets" do
      payload = parse_json_body!
      ticket = service.create_ticket(payload)
      json_response(201, { data: ticket.to_h })
    end

    patch "/tickets/:id" do
      payload = parse_json_body!
      ticket = service.update_ticket(params["id"], payload)
      json_response(200, { data: ticket.to_h })
    end

    delete "/tickets/:id" do
      service.delete_ticket(params["id"])
      status 204
      ""
    end

    error BadRequestError do
      json_error(400, "bad_request", env["sinatra.error"].message)
    end

    error NotFoundError do
      json_error(404, "not_found", env["sinatra.error"].message)
    end

    error ValidationError do
      json_error(422, "unprocessable_entity", env["sinatra.error"].message)
    end

    error StandardError do
      json_error(500, "internal_server_error", "Error interno inesperado")
    end

    not_found do
      json_error(404, "not_found", "Ruta no encontrada")
    end

    private

    def service
      settings.ticket_service
    end

    def parse_json_body!
      request.body.rewind
      raw = request.body.read.to_s.strip
      raise BadRequestError, "El cuerpo de la petición no puede estar vacío" if raw.empty?

      parsed = JSON.parse(raw)
      raise BadRequestError, "El cuerpo JSON debe ser un objeto" unless parsed.is_a?(Hash)

      parsed
    rescue JSON::ParserError
      raise BadRequestError, "JSON malformado en el cuerpo de la petición"
    end

    def json_response(http_status, payload)
      status http_status
      JSON.generate(payload)
    end

    def json_error(http_status, code, message)
      json_response(http_status, { error: { code: code, message: message } })
    end
  end
end
