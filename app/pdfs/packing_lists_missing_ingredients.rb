require 'prawn/measurement_extensions'

class PackingListsMissingIngredients < Prawn::Document
  include UnitsHelper
  include RecipeMixin

  FOOTER_SIZE = 10.mm
  MARGIN = 12.5.mm

  def initialize(box)
    super(
      page_size: 'A4',
      top_margin: MARGIN,
      margin: MARGIN,
      bottom_margin: MARGIN + FOOTER_SIZE)
    @box = box
    load_fonts
    body
  end

  def filename
    "#{I18n.l(@box.datetime, format: :sortable).parameterize}-packlisten-fehlmengen.pdf"
  end

  private

  def missing_ingredients_per_lane
    @missing_ingredients_per_lane ||= \
      MissingIngredient \
      .where(box: @box) \
      .includes(:ingredient, group: :packing_lane) \
      .group_by do |missing_ingredient|
        missing_ingredient.group.packing_lane
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
            float { text "Packstraße #{packing_lane} Fehlmengen", size: 10, align: :right }
            text "Kiste #{I18n.l @box.datetime, format: :short}", size: 10
            text "Seite #{page + 1} / #{total_pages}", size: 10, valign: :bottom, align: :right
          end
        end
      end
    end
  end

  def packing_lane(packing_lane)
    missing_ingredients = missing_ingredients_per_lane.fetch(packing_lane, []).group_by(&:ingredient)
    ingredients = missing_ingredients.keys.sort_by(&:name)
    ingredients.each_with_index do |ingredient, index|
      start_new_page if index != 0
      packing_list(ingredient, missing_ingredients[ingredient])
    end
  end

  def packing_list(ingredient, missing_ingredients)
    font('CabinSketch') do
      font_size(20) { text ingredient.name, style: :bold }
    end
    table(
      [%w[Gruppe Menge gepackt]] + table_data(missing_ingredients),
      header: true, position: :center, width: bounds.width
    ) do
      cells.borders = [:top]
      row(0).font_style = :bold
      row(0).borders = [:bottom]
      columns(1..3).align = :right
    end
  end

  def table_data(missing_ingredients)
    missing_ingredients \
      .sort_by { |missing_ingredient| missing_ingredient.group.display_name } \
      .map do |missing_ingredient|
        [
          missing_ingredient.group.display_name,
          missing_ingredient.quantity_unit.humanize,
          '[    ]          [    ]'
        ]
      end
  end
end
