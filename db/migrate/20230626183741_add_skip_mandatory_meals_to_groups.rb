class AddSkipMandatoryMealsToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :skip_mandatory_meals, :boolean, null: false, default: false
  end
end
