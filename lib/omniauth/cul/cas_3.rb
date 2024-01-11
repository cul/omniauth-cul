# frozen_string_literal: true

module Omniauth
  module Cul
    module Cas3
      # For Columbia CAS 3 endpoint info, see: https://www.cuit.columbia.edu/cas-authentication

      def self.passthru_redirect_url(app_cas_callback_endpoint)
        'https://cas.columbia.edu/cas/login?'\
        "service=#{Rack::Utils.escape(app_cas_callback_endpoint)}"
      end

      def self.validation_callback(ticket, app_cas_callback_endpoint)
        cas_ticket = ticket
        validation_url = cas_validation_url(app_cas_callback_endpoint, cas_ticket)
        validation_response = validate_ticket(validation_url, cas_ticket)

        # We are always expecting an XML response
        response_xml = Nokogiri::XML(validation_response)

        user_id = user_id_from_response_xml(response_xml)
        affils = affils_from_response_xml(response_xml)

        [user_id, affils]
      end

      def self.cas_validation_url(app_cas_callback_endpoint, cas_ticket)
        'https://cas.columbia.edu/cas/p3/serviceValidate?'\
        "service=#{Rack::Utils.escape(app_cas_callback_endpoint)}&"\
        "ticket=#{cas_ticket}"
      end

      def self.validate_ticket(validation_url, cas_ticket)
        uri = URI.parse(validation_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        validation_request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(validation_request)
        response.body
      end

      def self.user_id_from_response_xml(response_xml)
        response_xml.xpath('/cas:serviceResponse/cas:authenticationSuccess/cas:user', 'cas' => 'http://www.yale.edu/tp/cas')&.first&.text
      end

      def self.affils_from_response_xml(response_xml)
        response_xml.xpath('/cas:serviceResponse/cas:authenticationSuccess/cas:attributes/cas:affiliation', 'cas' => 'http://www.yale.edu/tp/cas')&.map(&:text)
      end
    end
  end
end
