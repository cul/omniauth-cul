# frozen_string_literal: true

module Omniauth::Cul::Exceptions
  class Error < StandardError; end
  class CasTicketValidationError < Error; end
end
