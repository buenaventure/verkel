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
      @groups ||= Group.order(internal_name: :asc, name: :asc).map { spending_for(it) }
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

    def timelines_by_group
      @timelines_by_group ||=
        GroupBoxCost
        .joins(:box)
        .includes(:box)
        .order('boxes.datetime ASC')
        .group_by(&:group_id)
        .transform_values { GroupSpending.build_timeline(it) }
    end

    private

    def spending_for(group)
      GroupSpending.new(
        group,
        timeline: timelines_by_group[group.id] || [],
        total_estimate: total_totals_by_group[group.id],
        final_total: final_totals_by_group[group.id],
        missing_price_article_count: missing_price_article_counts_by_group.fetch(group.id, 0)
      )
    end
  end

  def self.build_timeline(costs)
    costs.each_with_object([]) do |cost, timeline|
      previous = timeline.last
      cumulative_total = (previous&.fetch(:cumulative_total) || 0) + (cost.total_cost || 0)
      cumulative_final = (previous&.fetch(:cumulative_final) || 0) + (cost.is_final ? (cost.total_cost || 0) : 0)
      timeline << {
        datetime: cost.box.datetime.iso8601,
        cumulative_total: cumulative_total.to_f,
        cumulative_final: cumulative_final.to_f,
        is_final: cost.is_final,
        period_cost: cost.total_cost&.to_f
      }
    end
  end

  def self.overview = Overview.new

  def self.find(group_id)
    new(Group.find(group_id))
  end

  def initialize(group, **attrs)
    @group = group
    @spending_timeline = attrs[:timeline] if attrs.key?(:timeline)
    @final_total = attrs[:final_total] if attrs.key?(:final_total)
    @total_estimate = attrs[:total_estimate] if attrs.key?(:total_estimate)
    @missing_price_article_count = attrs[:missing_price_article_count] if attrs.key?(:missing_price_article_count)
  end

  attr_reader :group

  delegate :id, :display_name, :budget, to: :group

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
    return @final_total if instance_variable_defined?(:@final_total)

    @final_total = GroupBoxCost.final.where(group:).sum(:total_cost)
  end

  def total_estimate
    return @total_estimate if instance_variable_defined?(:@total_estimate)

    @total_estimate = GroupBoxCost.where(group:).sum(:total_cost)
  end

  def missing_price_article_count
    return @missing_price_article_count if instance_variable_defined?(:@missing_price_article_count)

    @missing_price_article_count = article_costs.select(&:missing_price?).map(&:article_id).uniq.count
  end

  def spending_timeline
    return @spending_timeline if instance_variable_defined?(:@spending_timeline)

    @spending_timeline =
      self.class.build_timeline(
        GroupBoxCost.where(group:).joins(:box).includes(:box).order('boxes.datetime ASC')
      )
  end

  def over_budget?
    budget.present? && total_estimate.to_d > budget.to_d
  end

  def sparkline?
    budget.present? && spending_timeline.any?
  end

  def near_budget?(threshold: 0.9)
    budget.present? && total_estimate.to_d >= budget.to_d * threshold && !over_budget?
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
