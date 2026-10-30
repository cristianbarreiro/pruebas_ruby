# frozen_string_literal: true

require_relative "ticket"
require_relative "ticket_repository"

module RestApi
  # Capa de aplicación que coordina las operaciones CRUD, el filtrado y las
  # reglas de negocio sobre los tickets de soporte.
  class TicketService
    def initialize(repository: TicketRepository.new)
      @repository = repository
    end

    def list_tickets(status: nil, priority: nil)
      tickets = @repository.all
      tickets = filter_by_status(tickets, status) if status && !status.strip.empty?
      tickets = filter_by_priority(tickets, priority) if priority && !priority.strip.empty?
      tickets
    end

    def find_ticket(ticket_id)
      ticket = @repository.find(ticket_id.to_s)
      raise NotFoundError, "Ticket '#{ticket_id}' no encontrado" unless ticket

      ticket
    end

    def create_ticket(attributes)
      ensure_hash!(attributes)
      ticket = Ticket.new(attributes.transform_keys(&:to_sym))
      @repository.save(ticket)
    end

    def update_ticket(ticket_id, changes)
      ensure_hash!(changes)
      raise ValidationError, "Debe enviar al menos un atributo para actualizar" if changes.empty?

      existing = find_ticket(ticket_id)
      updated = existing.with_updates(changes)
      @repository.save(updated)
    end

    def delete_ticket(ticket_id)
      removed = @repository.delete(ticket_id.to_s)
      raise NotFoundError, "Ticket '#{ticket_id}' no encontrado" unless removed

      removed
    end

    private

    def ensure_hash!(payload)
      raise BadRequestError, "El cuerpo JSON debe ser un objeto" unless payload.is_a?(Hash)
    end

    def filter_by_status(tickets, status)
      normalized = status.strip.downcase
      raise ValidationError, "Filtro 'status' inválido: #{status}" unless Ticket::STATUSES.include?(normalized)

      tickets.select { |item| item.status == normalized }
    end

    def filter_by_priority(tickets, priority)
      normalized = priority.strip.downcase
      raise ValidationError, "Filtro 'priority' inválido: #{priority}" unless Ticket::PRIORITIES.include?(normalized)

      tickets.select { |item| item.priority == normalized }
    end
  end
end
