# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Group do
  describe 'budget validation' do
    it 'allows nil budget' do
      group = build(:group, budget: nil)

      expect(group).to be_valid
    end

    it 'allows zero budget' do
      group = build(:group, budget: 0)

      expect(group).to be_valid
    end

    it 'rejects negative budget' do
      group = build(:group, budget: -1)

      expect(group).not_to be_valid
      expect(group.errors[:budget]).to be_present
    end
  end
end
