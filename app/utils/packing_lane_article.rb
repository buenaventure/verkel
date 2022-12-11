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

  def move_diff_from_stock
    quantity = [quantity_difference, article.stock].min
    return if quantity <= 0

    article.stock -= quantity
    article.save!
    if stock.nil?
      create_stock(quantity)
    else
      stock.quantity += quantity
      stock.save!
    end
  end

  def move_to_stock
    return if stock.nil?

    article.stock += stock.quantity
    article.save!
    stock.destroy!
  end

  def warm?
    !article.needs_cooling
  end

  def cold?
    article.needs_cooling
  end

  private

  def create_stock(quantity)
    PackingLaneArticleStock.create(
      packing_lane: packing_lane,
      article: article,
      quantity: quantity,
      box: box
    )
  end
end
