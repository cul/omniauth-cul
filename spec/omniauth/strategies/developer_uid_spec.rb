# frozen_string_literal: true

RSpec.describe Omniauth::Strategies::DeveloperUid do
  let(:rack_app) do
    instance_double('mock rack app')
  end

  let(:instance) do
    inst = described_class.new(rack_app)
    allow(inst).to receive(:callback_path).and_return('/callback')
    inst
  end

  it 'has the expected name value' do
    expect(described_class.new(rack_app).name).to eq(:developer_uid)
  end

  describe '#request_phase' do
    it 'renders the expected response and form' do
      status, headers, body = instance.request_phase
      expect(status).to eq(200)
      expect(headers).to eq({ 'content-type' => 'text/html' })
      expect(body[0]).to match(%r{\s*<!DOCTYPE html>.*<form.*>.+</form>.*</html>\s*}m)
    end
  end
end
