# frozen_string_literal: true

class AddBudgetToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :budget, :decimal, precision: 10, scale: 2
  end
end
