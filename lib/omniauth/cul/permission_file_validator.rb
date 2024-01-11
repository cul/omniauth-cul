# frozen_string_literal: true

module Omniauth
  module Cul
    module PermissionFileValidator
      # For Columbia CAS 3 endpoint info, see: https://www.cuit.columbia.edu/cas-authentication

      def self.permission_file_data
        return @permission_file_data if @permission_file_data
        @permission_file_data = {}
        if defined?(Rails)
          permission_file_path = Rails.root.join('config/permissions.yml')
          # We'll use YAML loading logic similar to Rails 7, for older and newer psych gem compatibility
          # https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/encrypted_configuration.rb#L99
          conf = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load_file(permission_file_path) : YAML.load_file(permission_file_path)
          @permission_file_data = conf[Rails.env] || {}
        end

        @permission_file_data
      end

      def self.allowed_user_ids
        permission_file_data.fetch('allowed_user_ids', [])
      end

      def self.allowed_user_affils
        permission_file_data.fetch('allowed_user_affils', [])
      end

      # Returns true if the given user_id OR affils match at least one of the rules defined in the
      # permissions.yml config file.  This method will always return false if user_id is nil.
      def self.permitted?(user_id, affils)
        return false if user_id.nil?
        return true if allowed_user_ids.include?(user_id)
        return true if affils.respond_to?(:include?) && allowed_user_affils.include?(affils)
        return false
      end
    end
  end
end
