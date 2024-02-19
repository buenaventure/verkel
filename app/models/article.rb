class Article < ApplicationRecord
  include NormalizedQuantityUnit

  enum packing_type: { bulk: 0, piece: 1 }

  belongs_to :supplier
  belongs_to :ingredient
  has_many :group_box_articles
  has_many :boxes, -> { distinct }, through: :group_box_articles
  has_many :article_box_order_requirements
  has_many :order_articles, dependent: :restrict_with_error
  has_many :packing_lane_article_stocks, dependent: :delete_all
  has_many :active_packing_lane_article_stocks, -> { where(box: Box.picked) }, class_name: 'PackingLaneArticleStock'
  has_many :hoards
  has_many :stock_changes, -> { order(created_at: :desc) }, dependent: :destroy

  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0 }
  validates :needs_cooling, inclusion: { in: [true, false] }
  validates :packing_type, presence: true
  validates :nr, uniqueness: true, if: -> { nr.present? }

  validates :quantity, numericality: { equal_to: 1, message: 'muss bei Schüttgut auf 1 gesetzt sein' }, if: :bulk?
  validates :unit, inclusion: { in: %w[g], message: 'erlaubt nur g bei Schüttgut' }, if: :bulk?

  default_scope { order(priority: :asc, quantity: :desc) }

  scope :lexical, -> { joins(:ingredient).reorder('ingredients.commodity_group', 'ingredients.name', 'priority') }

  def to_s
    nr_str = nr.nil? ? '' : "##{nr} "
    name_str = name.blank? ? '' : "\"#{name}\" "
    "#{nr_str}#{name_str}#{quantity_unit.humanize} #{ingredient}"
  end

  def full_name
    "#{self} von #{supplier}"
  end

  def ordering_name
    article_name = name && !name.blank? ? " - #{name}" : ''
    "#{ingredient.name}#{article_name}"
  end

  def packing_name
    article_name = name && !name.blank? ? " - #{name}" : ''
    "#{ingredient.name} - #{supplier.name}#{article_name}" + \
      if packing_type == 'piece'
        " - #{quantity_unit.humanize}"
      else
        ''
      end
  end

  def base_price
    return nil unless price && quantity && unit

    (price / quantity.to_d * (unit == 'g' || unit == 'ml' ? 1000 : 1)).round(2)
  end

  def ingredient_unit
    IngredientUnit.new(ingredient_id, unit)
  end

  def sums_by_box
    @sums_by_box ||= group_box_articles.group(:box_id).sum(:quantity)
  end

  def order_requirements
    @order_requirements ||= article_box_order_requirements.map { |abor| [abor.box_id, abor] }.to_h
  end

  def order_requirement_of(box)
    order_requirements.fetch(box.id, NoOrderRequirement.new)
  end

  def current_order_limit
    return nil if order_limit.nil? # unlimited

    [0, order_limit - quantity_ordered - quantity_delivered].max
  end

  def quantity_ordered
    order_articles.joins(:order).merge(Order.ordered).sum(&:quantity_ordered)
  end

  def quantity_delivered
    order_articles.joins(:order).merge(Order.delivered_or_stored).sum(&:quantity_delivered)
  end

  def quantity_unit_stock
    quantity_unit * stock
  end

  def packing_lane_stock
    active_packing_lane_article_stocks.sum(&:quantity)
  end

  def quantity_unit_packing_lane_stock
    quantity_unit * packing_lane_stock
  end

  def surplus
    stock + packing_lane_stock - article_box_order_requirements.sum(&:stock)
  end

  def quantity_unit_surplus
    quantity_unit * surplus
  end
end
