module Omniauth::Cul::CaseConverter
  def self.to_snake_case(str)
    str.split(/(?=[A-Z0-9])/).join("_").downcase
  end
end
