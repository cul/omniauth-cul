# frozen_string_literal: true

module Omniauth::Cul::Exceptions # rubocop:disable Style/ClassAndModuleChildren
  class Error < StandardError; end
  class CasTicketValidationError < Error; end
end
