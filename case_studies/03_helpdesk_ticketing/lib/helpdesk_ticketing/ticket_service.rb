# frozen_string_literal: true

require_relative "errors"
require_relative "ticket"
require_relative "transition_policy"

module HelpdeskTicketing
  # Servicio de aplicación que gestiona el ciclo de vida y métricas de los tickets.
  class TicketService
    def initialize(repository: nil, policy: TransitionPolicy.new)
      @repository = repository
      @policy = policy
      loaded = @repository ? @repository.load_tickets : []
      @tickets = loaded.to_h { |ticket| [ticket.id, ticket] }
    end

    def create_ticket(title:, description:, requester:, **opts)
      ticket_id = (opts[:id] || next_ticket_id).to_s.strip.upcase
      raise Errors::ValidationError, "El ticket #{ticket_id} ya existe" if @tickets.key?(ticket_id)

      ticket = Ticket.new(
        id: ticket_id, title: title, description: description, requester: requester, **opts.except(:id)
      )
      @tickets[ticket.id] = ticket
      persist!
      ticket
    end
    alias create create_ticket

    def find_ticket(ticket_id)
      norm_id = ticket_id.to_s.strip.upcase
      @tickets.fetch(norm_id) do
        raise Errors::NotFoundError, "No se encontró el ticket #{norm_id}"
      end
    end
    alias find find_ticket

    def assign_ticket(ticket_id, technician)
      ticket = find_ticket(ticket_id)
      ticket.assign_to(technician)
      persist!
      ticket
    end
    alias assign assign_ticket

    def transition_status(ticket_id, new_status, timestamp: nil, note: nil)
      ticket = find_ticket(ticket_id)
      ticket.transition_to(new_status, policy: @policy, timestamp: timestamp, note: note)
      persist!
      ticket
    end

    def all_tickets
      @tickets.values.sort_by(&:id)
    end

    def search(status: nil, priority: nil, assignee: nil, query: nil)
      all_tickets.select do |ticket|
        matches_status?(ticket, status) &&
          matches_priority?(ticket, priority) &&
          matches_assignee?(ticket, assignee) &&
          matches_query?(ticket, query)
      end
    end
    alias filter search

    def stats
      items = all_tickets
      {
        total: items.size,
        by_status: items.map(&:status).tally,
        by_priority: items.map(&:priority).tally,
        by_technician: count_by_technician(items),
        average_resolution_seconds: compute_average_resolution(items)
      }
    end

    private

    def next_ticket_id
      max_num = @tickets.keys.filter_map { |key| key[/\d+/]&.to_i }.max || 0
      format("TCK-%03d", max_num + 1)
    end

    def matches_status?(ticket, status)
      return true if status.nil? || status.to_s.strip.empty?

      ticket.status == status.to_s.strip.downcase.to_sym
    end

    def matches_priority?(ticket, priority)
      return true if priority.nil? || priority.to_s.strip.empty?

      ticket.priority == priority.to_s.strip.downcase.to_sym
    end

    def matches_assignee?(ticket, assignee)
      return true if assignee.nil? || assignee.to_s.strip.empty?

      ticket.assignee.to_s.casecmp?(assignee.to_s.strip)
    end

    def matches_query?(ticket, query)
      term = query.to_s.strip.downcase
      return true if term.empty?

      [ticket.id, ticket.title, ticket.description, ticket.requester, ticket.category].any? do |field|
        field.downcase.include?(term)
      end
    end

    def count_by_technician(items)
      items.each_with_object(Hash.new(0)) do |ticket, counts|
        key = ticket.assignee || "unassigned"
        counts[key] += 1
      end
    end

    def compute_average_resolution(items)
      durations = items.filter_map(&:resolution_seconds)
      return 0.0 if durations.empty?

      (durations.sum.to_f / durations.size).round(2)
    end

    def persist!
      @repository&.save_tickets(@tickets.values)
    end
  end
end
