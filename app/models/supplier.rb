class Supplier < ApplicationRecord
  has_many :articles, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_rich_text :notes

  validates :delivery_time, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true

  scope :with_next_order_data, lambda {
    Supplier.select(
      'suppliers.*, ' \
      '(SELECT datetime FROM article_box_order_requirements INNER JOIN articles ' \
      'ON articles.id = article_box_order_requirements.article_id ' \
      'INNER JOIN boxes ON boxes.id = article_box_order_requirements.box_id ' \
      'WHERE articles.supplier_id = suppliers.id AND article_box_order_requirements.quantity > 0 ' \
      'ORDER BY datetime LIMIT 1) as next_order_needed_date, ' \
      '((SELECT datetime FROM article_box_order_requirements INNER JOIN articles ' \
      'ON articles.id = article_box_order_requirements.article_id ' \
      'INNER JOIN boxes ON boxes.id = article_box_order_requirements.box_id ' \
      'WHERE articles.supplier_id = suppliers.id AND article_box_order_requirements.quantity > 0 ' \
      'ORDER BY datetime LIMIT 1) '\
      ' - suppliers.delivery_time * interval \'1 hour\') as next_required_order_date'
    )
  }

  def to_s
    name
  end

  def next_possible_delivery
    [Time.zone.now + delivery_time.hours, next_pending_order].compact.min
  end

  def next_pending_order
    orders.pending.minimum('lower(coverage)')&.in_time_zone
  end
end
