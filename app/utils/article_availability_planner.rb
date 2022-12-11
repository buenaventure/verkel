class ArticleAvailabilityPlanner
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

  delegate :id, :quantity, :priority, to: :@article

  def start_processing(box)
    @order_requirement = 0
    @stock = 0
    @ordered = 0
    @orderable = orderable_until?(box.datetime)
    advance_orders_to(box.datetime)
    advance_hoards_to(box.datetime)
  end

  def reserve(quantity)
    raise 'quantity may not be negative' if quantity.negative?

    reserved = reserve_stock(quantity)
    reserved += reserve_ordered(quantity - reserved)
    reserved += reserve_orderable(quantity - reserved)
    reserved
  end

  def available?
    @available_stock.positive? || @available_ordered.positive? || \
      (@orderable && (@available_to_order.nil? || @available_to_order.positive?))
  end

  def finish
    @hoards.each do |hoard|
      add_hoard_as_available(hoard)
    end
  end

  def order_requirements?
    !@order_requirement.zero? || !@stock.zero? || !@ordered.zero?
  end

  private

  def orderable_until?(datetime)
    @next_possible_delivery <= datetime
  end

  def reserve_stock(quantity)
    possible_quantity = [quantity, @available_stock].min
    @available_stock -= possible_quantity
    @stock += possible_quantity
    possible_quantity
  end

  def reserve_ordered(quantity)
    possible_quantity = [quantity, @available_ordered].min
    @available_ordered -= possible_quantity
    @ordered += possible_quantity
    possible_quantity
  end

  def reserve_orderable(quantity)
    return 0 unless @orderable

    if @available_to_order.nil?  # unlimited
      possible_quantity = quantity
    else
      possible_quantity = [quantity, @available_to_order].min
      @available_to_order -= possible_quantity
    end
    @order_requirement += possible_quantity
    possible_quantity
  end

  def advance_orders_to(datetime)
    @order_articles.map! do |order_article|
      if order_article.order.coverage_begin <= datetime
        add_order_article_as_available(order_article)
        nil
      else
        order_article
      end
    end.compact!
  end

  def add_order_article_as_available(order_article)
    @available_ordered += \
      case order_article.order.state
      when 'ordered' then order_article.quantity_ordered
      when 'delivered' then order_article.quantity_delivered
      else 0
      end
  end

  def advance_hoards_to(datetime)
    @hoards.map! do |hoard|
      if hoard.until <= datetime
        add_hoard_as_available(hoard)
        nil
      else
        hoard
      end
    end.compact!
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
