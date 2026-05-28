# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GroupChanges' do
  let(:user) { create(:user, role: :office) }
  let(:participant) { create(:participant) }
  let(:group) { create(:group) }

  before do
    sign_in user, scope: :user
  end

  describe 'POST /participants/:participant_id/group_changes' do
    it 'creates a group change' do
      expect { submit_group_change(1.week.from_now.beginning_of_day, 2.weeks.from_now.beginning_of_day) }
        .to change(GroupChange, :count).by(1)
    end

    it 'stores the submitted timeframe begin' do
      timeframe_begin = 1.week.from_now.beginning_of_day
      submit_group_change(timeframe_begin, 2.weeks.from_now.beginning_of_day)
      expect(GroupChange.last.timeframe_begin).to eq(timeframe_begin)
    end
  end

  describe 'PATCH /group_changes/:id' do
    let(:group_change) { create(:group_change, participant:, group:) }

    it 'updates the timeframe end' do
      new_timeframe_end = 3.weeks.from_now.beginning_of_day
      patch group_change_path(group_change),
            params: group_change_params(group_change.timeframe_begin, new_timeframe_end)
      expect(group_change.reload.timeframe_end).to eq(new_timeframe_end)
    end
  end

  def submit_group_change(timeframe_begin, timeframe_end)
    post participant_group_changes_path(participant), params: group_change_params(timeframe_begin, timeframe_end)
  end

  def group_change_params(timeframe_begin, timeframe_end)
    {
      group_change: {
        group_id: group.id,
        timeframe_begin:,
        timeframe_end:
      }
    }
  end
end
