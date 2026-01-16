class Order < ApplicationRecord
  enum :state, { planned: 0, ordered: 1, delivered: 2, stored: 3, canceled: -1 }
  belongs_to :supplier
  has_many :order_articles, dependent: :destroy
  has_many :articles, through: :order_articles

  validates :coverage, presence: true
  validates :coverage_begin, presence: true
  validates :coverage_end,
            presence: true,
            numericality: { greater_than: :coverage_begin, message: 'muss nach dem Liefertermin liegen' }

  accepts_nested_attributes_for :order_articles

  scope :pending, -> { planned.where('current_timestamp < lower(coverage)') }
  scope :delivered_or_stored, -> { delivered.or(stored) }
  default_scope { order(:coverage) }

  include DateTimeRange

  date_time_range :coverage

  def to_s
    "Bestellung bei #{supplier} für Zeitraum #{I18n.l coverage.begin.in_time_zone} bis #{I18n.l coverage.end.in_time_zone}"
  end

  def boxes
    Box.where("datetime <@ '[%s, %s)'::tsrange", coverage.begin, coverage.end)
  end

  def unordered_articles_of_supplier
    supplier.articles.where.not(id: articles)
  end

  def order_requirements
    ArticleBoxOrderRequirement
      .joins(:article)
      .where(box: boxes, 'articles.supplier_id': supplier_id)
  end

  def hoard_requirements
    Hoard
      .joins(:article).where('articles.supplier_id': supplier_id)
      .where("'%s' <= until", coverage.begin)
  end

  def required_articles
    Article
      .where(id: order_requirements.pluck(:article_id).union(hoard_requirements.pluck(:article_id)))
      .includes(:ingredient).joins(:ingredient).reorder('ingredients.name', 'articles.name')
  end

  def orderable?
    planned?
  end

  def order
    transaction do
      return false unless orderable?

      ordered!
      if order_articles_from_requirements.any?
        OrderArticle.insert_all(order_articles_from_requirements, unique_by: %i[order_id article_id])
      end
      order_requirements.destroy_all
      hoard_requirements.update_all(missing_quantity: 0)
    end
  end

  def deliverable?
    ordered?
  end

  def deliver
    transaction do
      return false unless deliverable?

      delivered!
      order_articles.update_all('quantity_delivered = quantity_ordered')
    end
  end

  def storable?
    delivered?
  end

  def store(user)
    transaction do
      return false unless storable?

      stored!
      order_articles.each do |order_article|
        article = order_article.article
        article.lock!
        article.stock += order_article.quantity_delivered
        article.save!
        StockChange.create!(
          article:, user:, quantity: order_article.quantity_delivered,
          result: article.stock, reference: to_global_id
        )
      end
    end
  end

  def cancelable?
    planned? || ordered?
  end

  def cancel
    transaction do
      return false unless cancelable?

      canceled!
    end
  end

  def order_requirements_by_article_box
    @order_requirements_by_article_box ||=
      order_requirements.group(:article_id, :box_id).sum(:quantity).to_h
  end

  def hoard_requirements_by_article
    @hoard_requirements_by_article ||=
      hoard_requirements.group(:article_id).sum(:missing_quantity).to_h
  end

  def requirements_by_article
    @requirements_by_article ||=
      order_requirements_by_article.merge(
        hoard_requirements_by_article
      ) do |_article_id, order_requirement, hoard_requirement|
        order_requirement + hoard_requirement
      end
  end

  def price_ordered
    order_articles.map(&:price_ordered).compact.sum.round(2)
  end

  def latest_order_date
    coverage_begin - supplier.delivery_time.hours
  end

  private

  def order_requirements_by_article
    order_requirements.group(:article_id).sum(:quantity).to_h
  end

  def order_articles_from_requirements
    @order_articles_from_requirements ||=
      requirements_by_article.map do |article_id, quantity_sum|
        {
          order_id: id,
          article_id:,
          quantity_ordered: quantity_sum
        }
      end
  end
end
