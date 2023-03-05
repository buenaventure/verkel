class UpdateGroupMealParticipantsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    replace_view :group_meal_participants, version: 2, revert_to_version: 1
  end
end
