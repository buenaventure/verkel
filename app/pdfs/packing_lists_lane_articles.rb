require 'prawn/measurement_extensions'

class PackingListsLaneArticles < Prawn::Document
  include UnitsHelper
  include RecipeMixin

  FOOTER_SIZE = 10.mm
  MARGIN = 12.5.mm

  def initialize(box, filter: nil)
    super(
      page_size: 'A4',
      top_margin: MARGIN,
      margin: MARGIN,
      bottom_margin: MARGIN + FOOTER_SIZE)
    @box = box
    @filter = filter
    load_fonts
    body
  end

  def filename
    date = I18n.l(@box.datetime, format: :sortable).parameterize
    "#{date}-packlisten-artikel-packstrassen-#{I18n.t(@filter || 'all')}.pdf"
  end

  private

  def packing_lane_articles
    @packing_lane_articles ||=
      PackingLane.order(:name).flat_map do |packing_lane|
        PackingLaneBox.new(packing_lane:, box: @box).packing_lane_articles
      end.select do |packing_lane_article|
        case @filter
        when :warm then packing_lane_article.warm?
        when :cold then packing_lane_article.cold?
        when nil then true
        else raise ArgumentError
        end
      end
  end

  def missing_ingredients_by_ingredient
    @missing_ingredients_by_ingredient ||=
      MissingIngredient
      .where(box: @box)
      .joins(group: :packing_lane)
      .includes(:ingredient, group: :packing_lane)
      .group_by(&:ingredient)
  end

  def body
    packing_lane_articles_by_ingredient = packing_lane_articles.group_by { |pla| pla.article.ingredient }
    packing_lane_articles_by_ingredient.keys.sort_by(&:name).each_with_index do |ingredient, index|
      start_new_page if index != 0
      first_page = page_number
      ingredient_packing_list(ingredient, packing_lane_articles_by_ingredient[ingredient])
      total_pages = (first_page..page_number).size
      (first_page..page_number).each_with_index do |i, page|
        go_to_page i
        canvas do
          bounding_box(
            [MARGIN, MARGIN + FOOTER_SIZE],
            width: bounds.right - (2 * MARGIN), height: FOOTER_SIZE
          ) do
            text "Kiste #{I18n.l @box.datetime, format: :short}", size: 10
            float do
              text "#{ingredient.name} #{I18n.t @filter}", size: 10, valign: :bottom, inline_format: true
            end
            text "Seite #{page + 1} / #{total_pages}", size: 10, valign: :bottom, align: :right
          end
        end
      end
    end
  end

  def ingredient_packing_list(ingredient, packing_lane_articles)
    font('CabinSketch') do
      font_size(20) { text ingredient.name, style: :bold }
    end

    packing_lane_articles_by_article = packing_lane_articles.group_by(&:article)
    articles = packing_lane_articles_by_article.keys.sort_by { |a| [a.supplier.name, a.name || ''] }

    articles.each_with_index do |article, article_index|
      font('CabinSketch') do
        font_size(16) { text article.packing_subheading, style: :bold }
      end

      text '– Artikel nur auf Nachfrage packen! –', style: :bold, size: 20, align: :center if article.on_demand?

      article_table(article, packing_lane_articles_by_article[article])

      # Add some space between articles, but not after the last one
      move_down 10 if article_index < articles.length - 1
    end

    missing_ingredients_table(ingredient)
  end

  def article_table(article, packing_lane_articles)
    table(
      [%w[Packstraße Soll Ist Fehl Ok]] + article_table_data(packing_lane_articles) +
      [['Summe',
        humanize_quantity_sum(article, packing_lane_articles, :required),
        humanize_quantity_sum(article, packing_lane_articles, :available),
        humanize_quantity_sum(article, packing_lane_articles, :difference),
        nil]],
      header: true, position: :center, width: bounds.width
    ) do
      cells.borders = [:top]
      row(0).font_style = :bold
      row(0).borders = [:bottom]
      columns(1..3).align = :right
      row(-1).font_style = :bold
    end
  end

  def article_table_data(packing_lane_articles)
    packing_lane_articles.sort_by { |pla| pla.packing_lane.name }.map do |packing_lane_article|
      [
        packing_lane_article.packing_lane.name,
        packing_lane_article.humanize_quantity(:required),
        packing_lane_article.humanize_quantity(:available),
        packing_lane_article.humanize_quantity(:difference),
        ''
      ]
    end
  end

  def humanize_quantity_sum(article, packing_lane_articles, kind)
    raise ArgumentError unless %i[required available difference].include?(kind)

    total_quantity = packing_lane_articles.sum { |pla| pla.send("quantity_#{kind}") }
    ArticleQuantity.new(article, total_quantity).humanize
  end

  def missing_ingredients_table(ingredient)
    entries = missing_ingredients_by_ingredient.fetch(ingredient, [])
    entries_by_lane = entries.group_by { |missing_ingredient| missing_ingredient.group.packing_lane.name }
    rows = entries_by_lane.map do |lane_name, mis|
      [lane_name, QuantityUnit.sum(mis.map(&:quantity_unit)).humanize]
    end.sort_by(&:first)

    return if rows.empty?

    move_down 30
    text 'Fehlmengen', style: :bold, size: 14
    table(
      [%w[Packstraße Menge]] + rows,
      header: true, position: :center, width: bounds.width
    ) do
      cells.borders = [:top]
      row(0).font_style = :bold
      row(0).borders = [:bottom]
      columns(1..1).align = :right
    end
  end
end
