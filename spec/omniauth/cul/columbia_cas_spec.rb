# frozen_string_literal: true

RSpec.describe Omniauth::Cul::ColumbiaCas do
  let(:cas_3_validation_response_success_xml_string) do
    fixture('cas-3-validation-response-success.xml').read
  end

  let(:cas_3_validation_response_success_xml_object) do
    Nokogiri::XML(cas_3_validation_response_success_xml_string)
  end

  let(:cas_3_validation_response_failure_xml_string) do
    fixture('cas-3-validation-response-failure.xml').read
  end

  let(:cas_3_validation_response_failure_xml_object) do
    Nokogiri::XML(cas_3_validation_response_failure_xml_string)
  end

  let(:expected_user_id) { 'zzz1234' }

  let(:expected_affils) do
    %w[
      CUNIX_swift
      CUL_allstaff
      CUL_dlst
      CNETrestricted
      CUNIX_ldpd
      CUNIX_ldpddev
      CUNIX_cul
      CUNIX_ldpdserv
      CUL_dpts-ldpd
      LIB_allstaff
      CUL_dpts-dev
      CUstaff
    ]
  end

  let(:app_cas_callback_endpoint) { 'https://example.com/cas_callback_url' }
  let(:url_encoded_app_cas_callback_endpoint) { Rack::Utils.escape(app_cas_callback_endpoint) }
  let(:ticket) { 'abc-123-def-456' }

  describe '.validation_callback' do
    context 'when validation is successful' do
      before do
        allow(described_class).to receive(:validate).and_return(cas_3_validation_response_success_xml_string)
      end

      it 'returns the expected user_id and affils' do
        expect(
          described_class.validation_callback(app_cas_callback_endpoint, ticket)
        ).to eq(
          [
            expected_user_id,
            expected_affils
          ]
        )
      end
    end

    context 'when validation fails' do
      before do
        allow(described_class).to receive(:validate).and_return(cas_3_validation_response_failure_xml_string)
      end

      it 'raises an exception' do
        expect {
          described_class.validation_callback(app_cas_callback_endpoint, ticket)
        }.to raise_error(Omniauth::Cul::Exceptions::CasTicketValidationError)
      end
    end
  end

  describe '.cas_validation_url' do
    it 'generates the correct url string' do
      expect(
        described_class.cas_validation_url(app_cas_callback_endpoint, ticket)
      ).to eq(
        'https://cas.columbia.edu/cas/p3/serviceValidate?'\
        "service=#{url_encoded_app_cas_callback_endpoint}&"\
        "ticket=#{ticket}"
      )
    end
  end

  describe '.validate' do
    let(:validation_url) { described_class.cas_validation_url(app_cas_callback_endpoint, ticket) }
    let(:expected_successful_response_body) { cas_3_validation_response_success_xml_string }
    let(:net_http_object) do
      http_dbl = instance_double(Net::HTTP)
      allow(http_dbl).to receive(:use_ssl=)
      response_dbl = instance_double(Net::HTTPResponse)
      allow(response_dbl).to receive(:body).and_return(expected_successful_response_body)
      allow(http_dbl).to receive(:request).and_return(response_dbl)
      http_dbl
    end

    before do
      allow(Net::HTTP).to receive(:new).and_return(net_http_object)
    end

    it 'returns the expected user_id and affils' do
      expect(
        described_class.validate(validation_url)
      ).to eq(expected_successful_response_body)
    end
  end

  describe '.user_id_from_response_xml' do
    it 'extracts the expected user id from a successful response' do
      expect(described_class.user_id_from_response_xml(cas_3_validation_response_success_xml_object)).to eq(
        expected_user_id
      )
    end

    it 'returns nil for a failure response' do
      expect(described_class.user_id_from_response_xml(cas_3_validation_response_failure_xml_object)).to eq(
        nil
      )
    end
  end

  describe '.affils_from_response_xml' do
    it 'extracts the expected affiliations from a successful response' do
      expect(
        described_class.affils_from_response_xml(cas_3_validation_response_success_xml_object)
      ).to eq(expected_affils)
    end

    it 'returns an empty array for a failure response' do
      expect(described_class.affils_from_response_xml(cas_3_validation_response_failure_xml_object)).to eq(
        []
      )
    end
  end
end
