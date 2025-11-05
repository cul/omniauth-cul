module Omniauth
  module Strategies
    class ColumbiaCas
      include OmniAuth::Strategy

      # IMPORTANT NOTE: By default, any Omniauth strategy class that has a PascalCase name that would be converted to a
      # downcased version (without underscores), which is not what we want.  So we must override the name option to use
      # proper snake_casing.  This is unfortunate because it means that a strategy like MyStrategy will become
      # :mystrategy by default, unless we set `option :name, :my_strategy`.
      #  You can see the original Omniauth implementation here:
      # https://github.com/omniauth/omniauth/blob/v2.1.4/lib/omniauth/strategy.rb#L139
      option :name, Omniauth::Cul::CaseConverter.to_snake_case(name.split("::").last).to_sym

      def request_phase
        redirect "https://cas.columbia.edu/cas/login?service=#{Rack::Utils.escape(callback_url)}"
      end
    end
  end
end
