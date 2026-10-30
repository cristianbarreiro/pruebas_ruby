# frozen_string_literal: true

module HelpdeskTicketing
  # Excepciones de dominio del sistema de tickets de soporte.
  module Errors
    class Error < StandardError; end
    class ValidationError < Error; end
    class InvalidTransitionError < Error; end
    class NotFoundError < Error; end
  end
end
