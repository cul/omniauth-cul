# frozen_string_literal: true

require 'omniauth'

module Omniauth
  module Strategies
    class DeveloperUid
      include OmniAuth::Strategy

      # IMPORTANT NOTE: By default, any Omniauth strategy class that has a PascalCase name that would be converted to a
      # downcased version (without underscores), which is not what we want.  So we must override the name option to use
      # proper snake_casing.  This is unfortunate because it means that a strategy like MyStrategy will become
      # :mystrategy by default, unless we set `option :name, :my_strategy`.
      #  You can see the original Omniauth implementation here:
      # https://github.com/omniauth/omniauth/blob/v2.1.4/lib/omniauth/strategy.rb#L139
      option :name, Omniauth::Cul::CaseConverter.to_snake_case(name.split('::').last).to_sym

      option :fields, [:uid]
      option :uid_field, :uid

      def request_phase # rubocop:disable Metrics/MethodLength
        form = OmniAuth::Form.new(
          title: 'Developer Sign-In',
          url: callback_path,
          header_info: <<~FOCUSSCRIPT
            <script>
              document.addEventListener("DOMContentLoaded", (event) => {
                // Automatically focus on the uid input element when the page loads
                document.getElementById('uid').focus();
              });
            </script>
          FOCUSSCRIPT
        )
        form.text_field 'UID', 'uid'
        form.button 'Sign In'
        form.to_response
      end
    end
  end
end
