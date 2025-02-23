PackingLaneArticle = Struct.new(:article, :quantity_required, :stock, :packing_lane, :box, keyword_init: true) do
  def quantity_available
    if stock.nil?
      0
    else
      stock.quantity
    end
  end

  def quantity_unit_required
    article.quantity_unit * quantity_required
  end

  def quantity_unit_available
    article.quantity_unit * quantity_available
  end

  def quantity_difference
    quantity_required - quantity_available
  end

  def quantity_unit_difference
    article.quantity_unit * quantity_difference
  end

  def quantities_not_null?
    quantity_required != 0 || quantity_available != 0
  end

  def move_diff_from_stock(user)
    return if article.on_demand?

    quantity = [quantity_difference, article.stock].min
    return if quantity <= 0

    change_article_stock(-quantity, user)
    if stock.nil?
      create_stock(quantity)
    else
      stock.quantity += quantity
      stock.save!
    end
  end

  def move_to_stock(user)
    return if stock.nil?

    change_article_stock(stock.quantity, user)
    stock.destroy!
  end

  def warm?
    !article.needs_cooling
  end

  def cold?
    article.needs_cooling
  end

  private

  def change_article_stock(quantity, user)
    article.lock!
    article.stock += quantity
    article.save!
    StockChange.create!(
      article:, user:, quantity:, result: article.stock,
      reference: PackingLaneBox.new(packing_lane:, box:).to_global_id
    )
  end

  def create_stock(quantity)
    PackingLaneArticleStock.create(
      packing_lane:,
      article:,
      quantity:,
      box:
    )
  end
end
