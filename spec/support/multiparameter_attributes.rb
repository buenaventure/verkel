# frozen_string_literal: true

# Helpers for building Rails multiparameter attribute hashes in request specs.
module MultiparameterAttributes
  # Inverse of ActiveModel::Type::DateTime's multiparameter assignment format.
  # See ActiveModel::Type::Helpers::AcceptsMultiparameterTime.
  def multiparameter_attributes(time)
    { 1 => time.year, 2 => time.month, 3 => time.day, 4 => time.hour, 5 => time.min }
  end
end

RSpec.configure do |config|
  config.include MultiparameterAttributes
end
