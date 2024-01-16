# frozen_string_literal: true

require_relative 'cul/version'
require_relative 'cul/cas_3'
require_relative 'cul/permission_file_validator'
require_relative 'cul/strategies/cas_3_strategy'

module Omniauth
  module Cul
    class Error < StandardError; end
    # Your code goes here...
  end
end
