class Box < ApplicationRecord
  enum :box_type, { default: 0, base_box: 1, fresh_box: 2 }
  enum :status, { stocked: 0, picked: 1, packed: 2 }

  has_many :box_meals
  has_many :meals, through: :box_meals
  has_many :group_box_ingredient_unit_caches
  has_many :ingredients, -> { distinct }, through: :group_box_ingredient_unit_caches
  has_many :groups, -> { distinct }, through: :group_box_ingredient_unit_caches
  has_many :extra_ingredients, dependent: :destroy
  has_many :missing_ingredients
  has_many :group_box_articles
  has_many :articles, -> { distinct }, through: :group_box_articles
  has_many :article_box_order_requirements
  has_rich_text :groups_info

  default_scope { order(datetime: :asc) }

  def to_s
    "Kiste am #{I18n.l datetime}"
  end

  def unit_sums
    @unit_sums =
      group_box_ingredient_unit_caches
      .group(:ingredient_id, :unit).sum(:quantity)
      .group_by { |k, _v| k[0] }
      .transform_values { |a| a.map { |b| QuantityUnit.new(b[1], b[0][1]) } }
  end

  def missing_ingredient_sums_by_ingredient
    @missing_ingredient_sums_by_ingredient =
      missing_ingredients
      .group(:ingredient_id, :unit).sum(:quantity)
      .group_by { |k, _v| k[0] }
      .transform_values { |a| a.map { |b| QuantityUnit.new(b[1], b[0][1]) } }
  end

  def sums_by_article
    @sums_by_article ||= group_box_articles.group(:article_id).sum(:quantity)
  end

  def order_requirements
    @order_requirements ||= article_box_order_requirements.index_by { |abor| abor.article_id }
  end

  def order_requirement_of(article)
    order_requirements.fetch(article.id, NoOrderRequirement.new)
  end

  def needs_order?
    article_box_order_requirements.where.not(quantity: 0).exists?
  end

  def awaiting_delivery?
    article_box_order_requirements.where.not(ordered: 0).exists?
  end

  def packing_lane_boxes
    PackingLane.order(:name).map do |packing_lane|
      PackingLaneBox.new(packing_lane:, box: self)
    end
  end
end
