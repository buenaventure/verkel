# frozen_string_literal: true

class GroupBox
  module Spending
    extend ActiveSupport::Concern

    def group_box_article_costs
      GroupBoxArticleCost
        .where(group:, box:)
        .joins(article: :ingredient)
        .includes(article: %i[supplier ingredient])
        .order('ingredients.name', 'articles.quantity': :desc)
    end

    def total_cost
      group_box_article_costs.sum(:line_total)
    end

    def cost_final?
      box.packed?
    end
  end
end
