class AddOnDemandToIngredients < ActiveRecord::Migration[7.2]
  def change
    add_column :ingredients, :on_demand, :boolean, null: false, default: false
  end
end
