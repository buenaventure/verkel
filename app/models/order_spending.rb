# frozen_string_literal: true

# Read model for the incoming/order-based cost overview and detail pages.
class OrderSpending
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion
  include Memery
  include Breadcrumb

  # Read model for the order spending overview matrix (rows: estimated arrival day).
  class Overview
    include Memery

    memoize def days
      (delivered_by_day.keys + ordered_by_day.keys + pending_by_day.keys).uniq.sort
    end

    memoize def delivered_by_day
      order_totals_by_day(Order.delivered_or_stored, :price_delivered)
    end

    memoize def ordered_by_day
      order_totals_by_day(Order.ordered, :price_ordered)
    end

    memoize def box_requirement_by_day
      totals_by_day(
        ArticleBoxOrderRequirement.where.not(quantity: 0).includes(:article, :box)
      ) { |requirement| requirement.box.datetime.to_date }
    end

    memoize def hoard_by_day
      totals_by_day(
        Hoard.where.not(missing_quantity: 0).includes(:article)
      ) { |hoard| hoard.until.to_date }
    end

    memoize def pending_by_day
      box_requirement_by_day.merge(hoard_by_day) { |_day, a, b| a + b }
    end

    memoize def total_delivered
      delivered_by_day.values.sum
    end

    memoize def total_ordered
      ordered_by_day.values.sum
    end

    memoize def total_pending
      pending_by_day.values.sum
    end

    def total_final
      total_delivered
    end

    def total_projected
      total_delivered + total_ordered + total_pending
    end

    memoize def missing_price_article_count
      missing_price_records.map(&:article_id).uniq.count
    end

    private

    def missing_price_records
      order_missing_price_records + box_requirement_missing_price_records + hoard_missing_price_records
    end

    def order_missing_price_records
      OrderArticle.joins(:order).merge(Order.where(state: %i[ordered delivered stored])).includes(:article)
                  .select { |order_article| order_article.article.price.nil? }
    end

    def box_requirement_missing_price_records
      ArticleBoxOrderRequirement.where.not(quantity: 0).includes(:article).select(&:missing_price?)
    end

    def hoard_missing_price_records
      Hoard.where.not(missing_quantity: 0).includes(:article).select(&:missing_price?)
    end

    def order_totals_by_day(order_scope, amount_method)
      totals_by_day(
        OrderArticle.joins(:order).merge(order_scope).includes(:article, :order).reorder(nil),
        amount: amount_method
      ) { |order_article| order_article.order.coverage_begin.to_date }
    end

    def totals_by_day(relation, amount: :line_total, &date_for)
      relation.group_by(&date_for)
              .transform_values { |records| records.filter_map(&amount).sum.round(2) }
    end
  end

  def self.overview = Overview.new

  def self.find(day)
    new(day.is_a?(Date) ? day : parse_day(day))
  end

  def self.parse_day(value)
    Date.parse(value.to_s)
  rescue Date::Error
    raise ActiveRecord::RecordNotFound, "Couldn't find #{name} for day #{value.inspect}"
  end

  def initialize(day)
    @day = day
  end

  attr_reader :day

  memoize def delivered_order_articles
    order_articles_for(Order.delivered_or_stored)
  end

  memoize def ordered_order_articles
    order_articles_for(Order.ordered)
  end

  memoize def box_requirements
    requirements_for(
      ArticleBoxOrderRequirement.where.not(quantity: 0).includes(article: :ingredient, box: [])
    ) { |requirement| requirement.box.datetime.to_date }
  end

  memoize def hoards
    requirements_for(
      Hoard.where.not(missing_quantity: 0).includes(article: :ingredient)
    ) { |hoard| hoard.until.to_date }
  end

  memoize def delivered_total
    total_for(delivered_order_articles, :price_delivered)
  end

  memoize def ordered_total
    total_for(ordered_order_articles, :price_ordered)
  end

  memoize def pending_total
    total_for(box_requirements, :line_total) + total_for(hoards, :line_total)
  end

  def total
    delivered_total + ordered_total + pending_total
  end

  def to_param
    day.iso8601
  end

  def to_key
    [day]
  end

  def persisted?
    true
  end

  def to_s
    I18n.l(day)
  end

  private

  def breadcrumb_parent
    Order
  end

  def order_articles_for(order_scope)
    OrderArticle.joins(:order).merge(order_scope).includes(:article, order: :supplier).reorder(nil)
                .select { |order_article| order_article.order.coverage_begin.to_date == day }
  end

  def requirements_for(relation)
    relation.select { |record| yield(record) == day }
  end

  def total_for(records, amount_method)
    records.filter_map(&amount_method).sum.round(2)
  end
end
