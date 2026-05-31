# frozen_string_literal: true

class CreateGroupBoxCostViews < ActiveRecord::Migration[8.0]
  def change
    create_view :group_box_article_costs
    create_view :group_box_costs
  end
end
