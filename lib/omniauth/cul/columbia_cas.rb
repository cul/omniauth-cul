# frozen_string_literal: true

require 'nokogiri'
require 'net/http'

module Omniauth
  module Cul
    # This module is built around the Columbia University CAS 3 endpoint.
    # For more information about this endpoint, see: https://www.cuit.columbia.edu/cas-authentication
    module ColumbiaCas
      def self.validation_callback(ticket, app_cas_callback_endpoint)
        cas_ticket = ticket
        validation_url = cas_validation_url(app_cas_callback_endpoint, cas_ticket)
        validation_response = validate(validation_url)

        # We are always expecting an XML response
        response_xml = Nokogiri::XML(validation_response)

        user_id = user_id_from_response_xml(response_xml)
        affils = affils_from_response_xml(response_xml)

        if user_id.nil?
          Rails.logger.error("Cas3 validation failed with validation response:\n#{response_xml}") if defined?(Rails)
          raise Omniauth::Cul::Exceptions::CasTicketValidationError,
                'Invalid CAS ticket'
        end

        [user_id, affils]
      end

      def self.cas_validation_url(app_cas_callback_endpoint, cas_ticket)
        'https://cas.columbia.edu/cas/p3/serviceValidate?'\
        "service=#{Rack::Utils.escape(app_cas_callback_endpoint)}&"\
        "ticket=#{cas_ticket}"
      end

      def self.validate(validation_url)
        uri = URI.parse(validation_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        validation_request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(validation_request)
        response.body
      end

      def self.user_id_from_response_xml(response_xml)
        unless response_xml.is_a?(Nokogiri::XML::Document)
          raise ArgumentError,
                'response_xml must be a Nokogiri::XML::Document'
        end

        response_xml.xpath('/cas:serviceResponse/cas:authenticationSuccess/cas:user', 'cas' => 'http://www.yale.edu/tp/cas')&.first&.text
      end

      def self.affils_from_response_xml(response_xml)
        puts response_xml.class.name.inspect
        unless response_xml.is_a?(Nokogiri::XML::Document)
          raise ArgumentError,
                'response_xml must be a Nokogiri::XML::Document'
        end

        response_xml.xpath('/cas:serviceResponse/cas:authenticationSuccess/cas:attributes/cas:affiliation', 'cas' => 'http://www.yale.edu/tp/cas')&.map(&:text)
      end
    end
  end
end
