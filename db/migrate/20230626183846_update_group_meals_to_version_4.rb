class UpdateGroupMealsToVersion4 < ActiveRecord::Migration[7.0]
  def change
    replace_view :group_meals, version: 4, revert_to_version: 3
  end
end
