class ArticleAvailabilityPlanner
  RESERVE_SOURCES = {
    full: %i[stock ordered orderable],
    immediate: %i[stock ordered],
    orderable: %i[orderable]
  }.freeze

  def initialize(article)
    @article = article
    @available_stock = article.stock + article.packing_lane_stock # quantity that is already there
    @order_articles = article.order_articles.includes(:order).to_a # stuff that is already ordered
    @available_ordered = 0 # quantity that should have arrived at the time the box is packed
    @available_to_order = article.current_order_limit # quantity that may be ordered without respect of arrival date
    @next_possible_delivery = article.supplier.next_possible_delivery
    @hoards = article.hoards.to_a # stuff that should be kept in stock as backup until a specific date
    @current_hoard = [@available_stock, @hoards.sum(&:quantity)].min # a subset of the stock that is blocked by hoards
    @available_stock -= @current_hoard
  end

  attr_reader :order_requirement, :stock, :ordered

  delegate :id, :quantity, :priority, :piece?, to: :@article

  def start_processing(box)
    @order_requirement = 0
    @stock = 0
    @ordered = 0
    @orderable = orderable_until?(box.datetime)
    advance_orders_to(box.datetime)
    advance_hoards_to(box.datetime)
  end

  def reserve(quantity, immediate_only: false, orderable_only: false)
    raise 'quantity may not be negative' if quantity.negative?

    remaining = quantity
    reserve_mode(immediate_only:, orderable_only:).sum do |source|
      reserved = send(:"reserve_#{source}", remaining)
      remaining -= reserved
      reserved
    end
  end

  def immediate_packages = @available_stock + @available_ordered

  def immediate_units = immediate_packages * quantity

  def orderable? = @orderable && remaining_orderable?

  def orderable_packages = orderable? ? (@available_to_order || Float::INFINITY) : 0

  def max_packages = immediate_packages + orderable_packages

  def total_coverable_units = unlimited_orderable? ? Float::INFINITY : immediate_units + (orderable_packages * quantity)

  def available? = immediate_packages.positive? || orderable?

  def finish = @hoards.each { add_hoard_as_available(it) }

  def order_requirements? = ![order_requirement, stock, ordered].all?(&:zero?)

  private

  def reserve_mode(immediate_only:, orderable_only:)
    return RESERVE_SOURCES[:orderable] if orderable_only
    return RESERVE_SOURCES[:immediate] if immediate_only

    RESERVE_SOURCES[:full]
  end

  def orderable_until?(datetime) = @next_possible_delivery <= datetime

  def remaining_orderable? = @available_to_order.nil? || @available_to_order.positive?

  def unlimited_orderable? = orderable? && @available_to_order.nil?

  def reserve_stock(quantity) = transfer(quantity, :@available_stock, :@stock)

  def reserve_ordered(quantity) = transfer(quantity, :@available_ordered, :@ordered)

  def transfer(quantity, pool_ivar, usage_ivar)
    taken = [quantity, instance_variable_get(pool_ivar)].min
    instance_variable_set(pool_ivar, instance_variable_get(pool_ivar) - taken)
    instance_variable_set(usage_ivar, instance_variable_get(usage_ivar) + taken)
    taken
  end

  def reserve_orderable(quantity)
    return 0 unless @orderable

    taken = @available_to_order.nil? ? quantity : [quantity, @available_to_order].min
    @available_to_order -= taken unless @available_to_order.nil?
    @order_requirement += taken
    taken
  end

  def advance_orders_to(datetime)
    remove_due(@order_articles) { it.order.coverage_begin <= datetime }
      .each { add_order_article_as_available(it) }
  end

  def advance_hoards_to(datetime)
    remove_due(@hoards) { it.until <= datetime }
      .each { add_hoard_as_available(it) }
  end

  def remove_due(items, &)
    due_items, remaining = items.partition(&)
    items.replace(remaining)
    due_items
  end

  def add_order_article_as_available(order_article)
    @available_ordered +=
      case order_article.order.state
      when 'ordered' then order_article.quantity_ordered
      when 'delivered' then order_article.quantity_delivered
      else 0
      end
  end

  def add_hoard_as_available(hoard)
    if @current_hoard < hoard.quantity
      hoard.missing_quantity = [hoard.quantity - @current_hoard - @available_ordered, 0].max
      @available_stock += @current_hoard
      @current_hoard = 0
    else
      hoard.missing_quantity = 0
      @available_stock += hoard.quantity
      @current_hoard -= hoard.quantity
    end
    hoard.save!
  end
end
