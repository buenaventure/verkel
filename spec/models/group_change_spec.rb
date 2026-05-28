require 'rails_helper'

RSpec.describe GroupChange do
  let(:participant) { Participant.create! age: 23 }

  describe 'timeframe' do
    it 'can be set to bounded time range' do
      group_change = described_class.create!(
        participant:,
        timeframe_begin: Time.zone.local(2024, 1, 1),
        timeframe_end: Time.zone.local(2024, 1, 2)
      )
      group_change.reload
      expect(group_change.timeframe_begin).to eq Time.zone.local(2024, 1, 1)
      expect(group_change.timeframe_end).to eq Time.zone.local(2024, 1, 2)
    end

    it 'allows begin to be unbounded' do
      group_change = described_class.create!(
        participant:,
        timeframe_begin: nil,
        timeframe_end: Time.zone.local(2024, 1, 2)
      )
      group_change.reload
      expect(group_change.timeframe_begin).to be_nil
      expect(group_change.timeframe_end).to eq Time.zone.local(2024, 1, 2)
    end

    it 'allows end to be unbounded' do
      group_change = described_class.create!(
        participant:,
        timeframe_begin: Time.zone.local(2024, 1, 1),
        timeframe_end: nil
      )
      group_change.reload
      expect(group_change.timeframe_begin).to eq Time.zone.local(2024, 1, 1)
      expect(group_change.timeframe_end).to be_nil
    end

    it 'can be completely unbounded' do
      group_change = described_class.create!(
        participant:,
        timeframe_begin: nil,
        timeframe_end: nil
      )
      group_change.reload
      expect(group_change.timeframe_begin).to be_nil
      expect(group_change.timeframe_end).to be_nil
    end
  end
end
