require 'prawn/measurement_extensions'

class PackingListsArticles < Prawn::Document
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
    "#{I18n.l(@box.datetime, format: :sortable).parameterize}-packlisten-artikel-#{I18n.t(@filter || 'all')}.pdf"
  end

  private

  def group_articles_per_lane
    @group_articles_per_lane ||= \
      GroupBoxArticle \
      .where(box: @box, **filter_arguments) \
      .non_zero \
      .includes(article: %i[ingredient supplier], group: :packing_lane) \
      .group_by do |group_article|
        group_article.group.packing_lane
      end
  end

  def body
    PackingLane.all.each_with_index do |packing_lane, index|
      start_new_page if index != 0
      first_page = page_number
      packing_lane(packing_lane)
      total_pages = (first_page..page_number).size
      (first_page..page_number).each_with_index do |i, page|
        go_to_page i
        canvas do
          bounding_box(
            [MARGIN, MARGIN + FOOTER_SIZE],
            width: bounds.right - 2 * MARGIN, height: FOOTER_SIZE
          ) do
            text "Kiste #{I18n.l @box.datetime, format: :short}", size: 10
            float do
              text "Packstraße <b>#{packing_lane}</b> #{I18n.t @filter}", size: 10, valign: :bottom, inline_format: true
            end
            text "Seite #{page + 1} / #{total_pages}", size: 10, valign: :bottom, align: :right
          end
        end
      end
    end
  end

  def packing_lane(packing_lane)
    group_articles = group_articles_per_lane.fetch(packing_lane, []).group_by(&:article)
    articles = group_articles.keys.sort_by { |ga| ga.ingredient.name }
    articles.each_with_index do |article, index|
      start_new_page if index != 0
      first_page = page_number
      packing_list(article, group_articles[article])
      (first_page..page_number).each do |i|
        go_to_page i
        canvas do
          bounding_box(
            [MARGIN, MARGIN + FOOTER_SIZE],
            width: bounds.right - 2 * MARGIN, height: FOOTER_SIZE
          ) do
            text article.packing_name, size: 10, align: :right
          end
        end
      end
    end
  end

  def packing_list(article, group_articles)
    font('CabinSketch') do
      font_size(20) { text article.packing_name, style: :bold }
    end
    table(
      [%w[Gruppe Menge gepackt]] + table_data(group_articles) +
      [['Summe',
        case article.packing_type
        when 'bulk' then QuantityUnit.sum(group_articles.map(&:quantity_unit)).humanize
        when 'piece' then number_with_delimiter group_articles.map(&:quantity).sum
        else raise ArgumentError
        end, nil]],
      header: true, position: :center, width: bounds.width
    ) do
      cells.borders = [:top]

      row(0).font_style = :bold
      row(0).borders = [:bottom]

      columns(1..3).align = :right
      row(-1).font_style = :bold
    end
  end

  def table_data(group_articles)
    group_articles.sort_by { |group_article| group_article.group.display_name }.map do |group_article|
      [
        group_article.group.display_name,
        group_article.humanize_quantity,
        '[    ]          [    ]'
      ]
    end
  end

  def filter_arguments
    case @filter
    when :warm then { article: { needs_cooling: false } }
    when :cold then { article: { needs_cooling: true } }
    when nil then {}
    else raise ArgumentError
    end
  end
end
