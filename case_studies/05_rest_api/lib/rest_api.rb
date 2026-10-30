# frozen_string_literal: true

# Namespace principal del caso de estudio 05: API REST JSON con Sinatra.
module RestApi
  class Error < StandardError; end
  class BadRequestError < Error; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
end

require_relative "rest_api/ticket"
require_relative "rest_api/ticket_repository"
require_relative "rest_api/ticket_service"
require_relative "rest_api/app"
