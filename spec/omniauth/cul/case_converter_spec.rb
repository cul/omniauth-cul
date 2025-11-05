# frozen_string_literal: true

RSpec.describe Omniauth::Cul::CaseConverter do
  describe ".to_snake_case" do
    {
      "SomeValue" => "some_value",
      "ABC" => "a_b_c",
      "TheFantastic4" => "the_fantastic_4"
    }.each do |before, after|
      it "convert #{before} to #{after}" do
        expect(described_class.to_snake_case(before)).to eq(after)
      end
    end
  end
end
