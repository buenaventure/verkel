require 'prawn/measurement_extensions'

class PackingListLane < Prawn::Document
  include UnitsHelper
  include RecipeMixin

  FOOTER_SIZE = 10.mm
  MARGIN = 12.5.mm

  def initialize(packing_lane_box, filter: nil)
    super(
      page_size: 'A4',
      top_margin: MARGIN,
      margin: MARGIN,
      bottom_margin: MARGIN + FOOTER_SIZE)
    @packing_lane_box = packing_lane_box
    @filter = filter
    load_fonts
    body
  end

  delegate :box, to: :@packing_lane_box

  delegate :packing_lane, to: :@packing_lane_box

  def packing_lane_articles
    case @filter
    when :warm then @packing_lane_box.packing_lane_articles.select(&:warm?)
    when :cold then @packing_lane_box.packing_lane_articles.select(&:cold?)
    when nil then @packing_lane_box.packing_lane_articles
    else raise ArgumentError
    end
  end

  def filename
    "#{I18n.l(box.datetime, format: :sortable).parameterize}-packliste-" \
      "#{packing_lane.name.parameterize}-#{I18n.t(@filter || 'all')}.pdf"
  end

  private

  def body
    first_page = page_number
    font('CabinSketch') do
      font_size(20) { text 'Packstraßen-Packliste', style: :bold }
    end
    articles_table
    missing_ingredients_table
    total_pages = (first_page..page_number).size
    (first_page..page_number).each_with_index do |i, page|
      go_to_page i
      canvas do
        bounding_box(
          [MARGIN, MARGIN + FOOTER_SIZE],
          width: bounds.right - (2 * MARGIN), height: FOOTER_SIZE
        ) do
          float do
            text "Packstraße <b>#{packing_lane.name}</b> #{I18n.t @filter}",
                 size: 10, align: :right, inline_format: true
          end
          text "Kiste #{I18n.l box.datetime, format: :short}", size: 10
          float { text "Stand #{I18n.l Time.zone.now}", size: 10, valign: :bottom }
          text "Seite #{page + 1} / #{total_pages}", size: 10, valign: :bottom, align: :right
        end
      end
    end
  end

  def articles_table
    table(
      [%w[Name Soll Ist Fehl Ok]] + articles_table_data,
      header: true, position: :center, width: bounds.width,
      column_widths: { 1 => 60, 2 => 60, 3 => 60 }
    ) do
      cells.borders = [:top]

      row(0).font_style = :bold
      row(0).borders = [:bottom]

      columns(1..3).align = :right
    end
  end

  def articles_table_data
    packing_lane_articles.map do |packing_lane_article|
      [
        packing_lane_article.article.packing_name,
        humanize_quantity(packing_lane_article, :required),
        humanize_quantity(packing_lane_article, :available),
        humanize_quantity(packing_lane_article, :difference),
        ''
      ]
    end
  end

  def humanize_quantity(packing_lane_article, kind)
    raise ArgumentError unless %i[required available difference].include?(kind)

    number_with_delimiter(
      case packing_lane_article.article.packing_type
      when 'bulk' then packing_lane_article.send("quantity_unit_#{kind}").humanize
      when 'piece' then packing_lane_article.send("quantity_#{kind}")
      else raise ArgumentError
      end
    )
  end

  def missing_ingredients_table
    return unless (table_data = missing_ingredient_table_data).any?

    move_down 30
    text 'Fehlmengen', style: :bold, size: 14
    table(
      [%w[Name Menge]] + table_data,
      header: true, position: :center, width: bounds.width
    ) do
      cells.borders = [:top]

      row(0).font_style = :bold
      row(0).borders = [:bottom]

      columns(1..3).align = :right
    end
  end

  def missing_ingredient_table_data
    @packing_lane_box.missing_ingredients.map do |missing_ingredient|
      [missing_ingredient[0].name, QuantityUnit.new(missing_ingredient[2], missing_ingredient[1]).humanize]
    end
  end
end
