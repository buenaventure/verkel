class ArticleAvailabilityPlanner
  # Which reservation methods each `only:` mode draws from, in order.
  RESERVE_SOURCES = {
    full: %i[reserve_stock reserve_ordered reserve_orderable],
    immediate: %i[reserve_stock reserve_ordered],
    orderable: %i[reserve_orderable]
  }.freeze
  RESERVE_ONLY = [nil, :immediate, :orderable].freeze

  def initialize(article)
    @article = article
    @available_stock = article.stock + article.packing_lane_stock # quantity that is already there
    @available_to_order = article.current_order_limit # quantity that may be ordered without respect of arrival date
    @next_possible_delivery = article.supplier.next_possible_delivery
    track_incoming_orders(article)
    block_hoarded_stock(article)
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

  def reserve(quantity, only: nil)
    raise 'quantity may not be negative' if quantity.negative?
    raise ArgumentError, "invalid only: #{only.inspect}" unless RESERVE_ONLY.include?(only)

    remaining = quantity
    RESERVE_SOURCES.fetch(only || :full).sum do |source|
      reserved = send(source, remaining)
      remaining -= reserved
      reserved
    end
  end

  # Packages this article can still contribute in a given reservation mode.
  # Float::INFINITY means the supplier sets no order limit.
  def packages_for(only)
    case only
    when :immediate then immediate_packages
    when :orderable then orderable_packages
    else max_packages
    end
  end

  def immediate_packages = @available_stock + @available_ordered

  def immediate_units = immediate_packages * quantity

  def orderable? = @orderable && remaining_orderable?

  def orderable_packages = orderable? ? (@available_to_order || Float::INFINITY) : 0

  def max_packages = immediate_packages + orderable_packages

  def total_coverable_units = max_packages * quantity

  def available? = immediate_packages.positive? || orderable?

  # Hoards still running after the last box: deliveries arriving before a
  # hoard's date still count as its backup.
  def finish
    @hoards.each do |hoard|
      advance_orders_to(hoard.until)
      release_hoard(hoard)
    end
  end

  def order_requirements? = [order_requirement, stock, ordered].any?(&:nonzero?)

  private

  def track_incoming_orders(article)
    @order_articles = article.order_articles.includes(:order).to_a # stuff that is already ordered
    @available_ordered = 0 # quantity that should have arrived at the time the box is packed
    @arrived_ordered = 0 # all incoming quantity that has arrived so far
    @credited_to_hoards = 0 # arrived quantity already counted as some hoard's backup
  end

  # Hoards: stuff that should be kept in stock as backup until a specific date.
  # They are released in this order, which decides which hoard absorbs a shortfall.
  def block_hoarded_stock(article)
    @hoards = article.hoards.order(:until, :id).to_a
    @current_hoard = [@available_stock, @hoards.sum(&:quantity)].min # a subset of the stock that is blocked by hoards
    @available_stock -= @current_hoard
  end

  def orderable_until?(datetime) = @next_possible_delivery <= datetime

  def remaining_orderable? = @available_to_order.nil? || @available_to_order.positive?

  def reserve_stock(quantity)
    taken = [quantity, @available_stock].min
    @available_stock -= taken
    @stock += taken
    taken
  end

  def reserve_ordered(quantity)
    taken = [quantity, @available_ordered].min
    @available_ordered -= taken
    @ordered += taken
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
    remove_due(@hoards) { it.until <= datetime }.each { release_hoard(it) }
  end

  def remove_due(items, &)
    due_items, remaining = items.partition(&)
    items.replace(remaining)
    due_items
  end

  def add_order_article_as_available(order_article)
    quantity = order_article.quantity_incoming
    @available_ordered += quantity
    @arrived_ordered += quantity
  end

  # A hoard must be backed for its whole lifetime, from now until its date. It
  # is covered from blocked stock first, then from delivered goods still on hand
  # that no earlier hoard has counted: all hoards run from now, so their
  # lifetimes overlap and one delivered unit can back only one of them.
  # Releasing a hoard frees its stock for boxes; counted goods stay packable
  # either way, as boxes are served before hoards from deliveries.
  def release_hoard(hoard)
    from_stock = [@current_hoard, hoard.quantity].min
    @current_hoard -= from_stock
    @available_stock += from_stock
    uncounted = [@available_ordered, @arrived_ordered - @credited_to_hoards].min
    from_incoming = [uncounted, hoard.quantity - from_stock].min
    @credited_to_hoards += from_incoming
    hoard.missing_quantity = hoard.quantity - from_stock - from_incoming
    hoard.save!
  end
end
