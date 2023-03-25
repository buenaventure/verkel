class UpdateGroupMealsToVersion3 < ActiveRecord::Migration[7.0]
  def change
    replace_view :group_meals, version: 3, revert_to_version: 2
  end
end
