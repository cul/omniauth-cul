# frozen_string_literal: true

require_relative 'cul/version'

require_relative 'cul/permission_file_validator'
require_relative 'cul/case_converter'
require_relative 'cul/exceptions'
require_relative 'cul/columbia_cas'

require_relative 'strategies/developer_uid'
require_relative 'strategies/columbia_cas'

module Omniauth
  module Cul
  end
end
