# frozen_string_literal: true

RSpec.describe Omniauth::Strategies::ColumbiaCas do
  let(:rack_app) do
    double("mock rack app")
  end

  let(:instance) do
    inst = described_class.new(rack_app)
    allow(inst).to receive(:callback_url).and_return("https://example.com/callback")
    inst
  end

  it "has the expected name value" do
    expect(instance.name).to eq(:columbia_cas)
  end

  describe "#request_phase" do
    it "performs the expected redirect" do
      expect(instance).to receive(:redirect).with("https://cas.columbia.edu/cas/login?service=#{Rack::Utils.escape(instance.callback_url)}")
      instance.request_phase
    end
  end
end
