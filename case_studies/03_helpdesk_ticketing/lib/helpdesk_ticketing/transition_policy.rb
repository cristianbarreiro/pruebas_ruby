# frozen_string_literal: true

require_relative "errors"

module HelpdeskTicketing
  # Política independiente que gobierna las transiciones válidas entre estados de un ticket.
  class TransitionPolicy
    ALLOWED_TRANSITIONS = {
      open: %i[in_progress],
      in_progress: %i[pending resolved],
      pending: %i[in_progress resolved],
      resolved: %i[open]
    }.freeze

    VALID_STATUSES = ALLOWED_TRANSITIONS.keys.freeze

    def self.valid_status?(status)
      new.valid_status?(status)
    end

    def self.allowed_targets(from_status)
      new.allowed_targets(from_status)
    end

    def self.can_transition?(from_status, to_status)
      new.can_transition?(from_status, to_status)
    end

    def self.validate!(from_status, to_status)
      new.validate!(from_status, to_status)
    end

    def valid_status?(status)
      VALID_STATUSES.include?(normalize_status(status))
    end

    def allowed_targets(from_status)
      ALLOWED_TRANSITIONS.fetch(normalize_status(from_status), [])
    end

    def can_transition?(from_status, to_status)
      allowed_targets(from_status).include?(normalize_status(to_status))
    end

    def validate!(from_status, to_status)
      origin = ensure_known_status(from_status)
      target = ensure_known_status(to_status)
      return true if can_transition?(origin, target)

      raise Errors::InvalidTransitionError,
            "Transición inválida de #{origin} a #{target} (permitidos: #{allowed_targets(origin).join(", ")})"
    end

    private

    def ensure_known_status(status)
      sym = normalize_status(status)
      return sym if VALID_STATUSES.include?(sym)

      raise Errors::ValidationError, "Estado de ticket desconocido: #{status}"
    end

    def normalize_status(status)
      status.to_s.strip.downcase.to_sym
    end
  end
end
