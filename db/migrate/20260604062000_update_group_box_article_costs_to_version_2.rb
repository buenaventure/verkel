# frozen_string_literal: true

# Keeps cost rows visible when article prices are missing.
class UpdateGroupBoxArticleCostsToVersion2 < ActiveRecord::Migration[8.0]
  def change
    update_view :group_box_article_costs, version: 2, revert_to_version: 1
  end
end
