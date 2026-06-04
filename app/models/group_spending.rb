# frozen_string_literal: true

# Read model for group spending overview and detail pages.
class GroupSpending
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion
  include Breadcrumb

  # Read model for the group spending overview matrix.
  class Overview
    def groups
      @groups ||= Group.order(internal_name: :asc, name: :asc).all
    end

    def boxes
      @boxes ||= Box.order(datetime: :asc).all
    end

    def costs_by_group_and_box
      @costs_by_group_and_box ||= GroupBoxCost.indexed_by_group_and_box
    end

    def final_totals_by_group
      @final_totals_by_group ||= GroupBoxCost.final_totals_by_group
    end

    def total_totals_by_group
      @total_totals_by_group ||= GroupBoxCost.totals_by_group
    end

    def missing_price_article_counts_by_group
      @missing_price_article_counts_by_group ||=
        GroupBoxArticleCost.missing_price.group(:group_id).distinct.count(:article_id)
    end
  end

  def self.overview = Overview.new

  def self.find(group_id)
    new(Group.find(group_id))
  end

  def initialize(group)
    @group = group
  end

  attr_reader :group

  delegate :display_name, to: :group

  def article_costs
    @article_costs ||=
      GroupBoxArticleCost
      .where(group:)
      .joins(:box, article: :ingredient)
      .includes(article: %i[supplier ingredient], box: [])
      .order('boxes.datetime ASC', 'ingredients.name ASC', 'articles.quantity DESC')
  end

  def costs_by_box
    @costs_by_box ||= article_costs.group_by(&:box)
  end

  def final_total
    @final_total ||= GroupBoxCost.final.where(group:).sum(:total_cost)
  end

  def total_estimate
    @total_estimate ||= GroupBoxCost.where(group:).sum(:total_cost)
  end

  def missing_price_article_count
    @missing_price_article_count ||= article_costs.select(&:missing_price?).map(&:article_id).uniq.count
  end

  def to_param
    group.id.to_s
  end

  def to_key
    [group.id]
  end

  def persisted?
    true
  end

  def to_s
    group.display_name
  end

  private

  def breadcrumb_parent
    Group
  end
end
