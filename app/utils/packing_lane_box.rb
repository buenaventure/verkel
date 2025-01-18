class PackingLaneBox
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include GlobalID::Identification
  include Breadcrumb

  def initialize(packing_lane:, box:)
    @packing_lane = packing_lane
    @box = box
    @errors = ActiveModel::Errors.new(self)
  end

  attr_reader :packing_lane, :box, :errors

  delegate :groups, to: :packing_lane

  def to_key
    [packing_lane.id, box.id]
  end

  def to_model
    self
  end

  alias id to_param

  def self.find(key)
    packing_lane_id, box_id = key.split('-')
    new(packing_lane: PackingLane.find(packing_lane_id), box: Box.find(box_id))
  end

  def persisted?
    true
  end

  def to_s
    "Packstraße #{packing_lane.name} für #{box}"
  end

  def update(attributes)
    if attributes.key? 'packing_lane_article_stocks_attributes'
      self.packing_lane_article_stocks_attributes = attributes['packing_lane_article_stocks_attributes']
      packing_lane_article_stocks.all? do |packing_lane_article_stock|
        result = packing_lane_article_stock.save
        errors.merge! packing_lane_article_stock.errors
        result
      end
    else
      true
    end
  end

  def packing_lane_article_stocks
    @packing_lane_article_stocks ||= \
      packing_lane.packing_lane_article_stocks.where(box: box)
  end

  def packing_lane_article_stocks_attributes=(attributes_collection)
    attributes_collection = attributes_collection.values
    attributes_collection.each do |attributes|
      attributes = attributes.to_h
      if (existing_record = packing_lane_article_stocks.detect { |record| record.id.to_s == attributes['id'].to_s })
        existing_record.assign_attributes(attributes.except('id'))
      else
        raise RecordNotFound.new(
          "Couldn't find PackingLaneArticleStock with ID=#{attributes['id']} for"\
          "PackingLane with ID=#{packing_lane.id} and Box with ID=#{box.id}",
          PackingLaneArticleStock, 'id', attributes['id']
        )
      end
    end
  end

  def group_box_article_sums
    @group_box_article_sums ||= \
      GroupBoxArticle\
      .where(group: groups, box: box)\
      .group(:article_id).sum(:quantity)
  end

  def packing_lane_article_stock_sums
    @packing_lane_article_stock_sums ||= \
      packing_lane_article_stocks.map { |stock| [stock.article_id, stock] }.to_h
  end

  def articles
    Article\
      .where(id: group_box_article_sums.keys + packing_lane_article_stock_sums.keys) \
      .includes(:ingredient)
      .reorder('ingredients.name')
  end

  def packing_lane_articles
    articles.map do |article|
      PackingLaneArticle.new(
        article:,
        quantity_required: group_box_article_sums.fetch(article.id, 0),
        stock: packing_lane_article_stock_sums.fetch(article.id, nil),
        packing_lane:,
        box:
      )
    end.select(&:quantities_not_null?)
  end

  def missing_ingredients
    sums = MissingIngredient \
           .where(box:, 'groups.packing_lane_id': packing_lane.id).includes(:ingredient, group: :packing_lane) \
           .group(:ingredient_id, :unit).sum(:quantity)
    ingredients = Ingredient.where(id: sums.keys.map { |key| key[0] }).map { |i| [i.id, i] }.to_h
    sums.map do |key, sum|
      [ingredients[key[0]], key[1], sum]
    end
  end

  def move_diff_from_stock(user)
    ActiveRecord::Base.transaction do
      packing_lane_articles.each { _1.move_diff_from_stock user }
    end
  end

  def move_to_stock(user)
    ActiveRecord::Base.transaction do
      packing_lane_articles.each { _1.move_to_stock user }
    end
  end

  def unstocked_articles
    Article.where.not(id: articles)
  end

  def deficiency?
    packing_lane_articles.any? do |packing_lane_article|
      packing_lane_article.quantity_difference.positive?
    end
  end

  def surplus?
    packing_lane_articles.any? do |packing_lane_article|
      packing_lane_article.quantity_difference.negative?
    end
  end

  private

  def breadcrumb_parent
    packing_lane
  end
end
