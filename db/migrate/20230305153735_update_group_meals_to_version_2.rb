class UpdateGroupMealsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view :group_meals, version: 2, revert_to_version: 1
  end
end
