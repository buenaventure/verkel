require 'rails_helper'

RSpec.describe Unit, type: :model do
  it { is_expected.to validate_uniqueness_of :name }
end
