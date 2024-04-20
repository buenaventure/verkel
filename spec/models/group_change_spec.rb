require 'rails_helper'

RSpec.describe GroupChange, type: :model do
  let(:participant) { Participant.create! age: 23 }
  describe 'timeframe' do
    it 'can be set to bounded time range' do
      group_change = GroupChange.create!(
        participant:,
        timeframe_begin: { 3 => 1, 2 => 1, 1 => 2024, 4 => 0, 5 => 0 },
        timeframe_end: { 3 => 2, 2 => 1, 1 => 2024, 4 => 0, 5 => 0 }
      )
      group_change.reload
      expect(group_change.timeframe_begin).to eq Time.zone.local(2024, 1, 1)
      expect(group_change.timeframe_end).to eq Time.zone.local(2024, 1, 2)
    end

    it 'allows begin to be unbounded' do
      group_change = GroupChange.create!(
        participant:,
        timeframe_begin: { 3 => nil, 2 => nil, 1 => nil, 4 => nil, 5 => nil },
        timeframe_end: { 3 => 2, 2 => 1, 1 => 2024, 4 => 0, 5 => 0 }
      )
      group_change.reload
      expect(group_change.timeframe_begin).to be_nil
      expect(group_change.timeframe_end).to eq Time.zone.local(2024, 1, 2)
    end

    it 'allows end to be unbounded' do
      group_change = GroupChange.create!(
        participant:,
        timeframe_begin: { 3 => 1, 2 => 1, 1 => 2024, 4 => 0, 5 => 0 },
        timeframe_end: { 3 => nil, 2 => nil, 1 => nil, 4 => nil, 5 => nil }
      )
      group_change.reload
      expect(group_change.timeframe_begin).to eq Time.zone.local(2024, 1, 1)
      expect(group_change.timeframe_end).to be_nil
    end

    it 'can be completely unbounded' do
      group_change = GroupChange.create!(
        participant:,
        timeframe_begin: { 3 => nil, 2 => nil, 1 => nil, 4 => nil, 5 => nil },
        timeframe_end: { 3 => nil, 2 => nil, 1 => nil, 4 => nil, 5 => nil }
      )
      group_change.reload
      expect(group_change.timeframe_begin).to be_nil
      expect(group_change.timeframe_end).to be_nil
    end
  end
end
