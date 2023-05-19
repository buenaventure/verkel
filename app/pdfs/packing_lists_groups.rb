require 'prawn/measurement_extensions'

class PackingListsGroups < Prawn::Document
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
    @group_articles = \
      GroupBoxArticle \
      .where(box: @box) \
      .non_zero \
      .joins(article: :ingredient) \
      .includes(:group, article: %i[supplier ingredient]) \
      .order('ingredients.name', 'articles.quantity': :desc) \
      .group_by(&:group)
    @missing_ingredients = \
      MissingIngredient \
      .where(box: @box) \
      .joins(:ingredient) \
      .includes(:group, :ingredient) \
      .order('ingredients.name') \
      .group_by(&:group)
    load_fonts
    body
  end

  def filename
    "#{I18n.l(@box.datetime, format: :sortable).parameterize}-packlisten-gruppen.pdf"
  end

  private

  def body
    @box.groups.includes(:packing_lane)
        .reorder('packing_lanes.name', :internal_name, :name)
        .each_with_index do |group, index|
      start_new_page if index != 0
      first_page = page_number
      groups_info unless @box.groups_info.blank?
      packing_list(group)
      total_pages = (first_page..page_number).size
      (first_page..page_number).each_with_index do |i, page|
        go_to_page i
        canvas do
          bounding_box(
            [MARGIN, MARGIN + FOOTER_SIZE],
            width: bounds.right - 2 * MARGIN, height: FOOTER_SIZE
            ) do
            float { text group.display_name, size: 10, align: :right }
            text "Kiste #{I18n.l @box.datetime, format: :short}", size: 10
            float { text "Seite #{page + 1} / #{total_pages}", size: 10, valign: :bottom, align: :right }
            if group.packing_lane
              text "Packstraße <b>#{group.packing_lane.name}</b>", size: 10, valign: :bottom, inline_format: true
            else
              text 'Packstraße fehlt', size: 10, style: :bold, color: 'FF0000', valign: :bottom
            end
          end
        end
      end
    end
  end

  def packing_list(group)
    font('CabinSketch') do
      font_size(20) { text group.display_name, style: :bold }
    end
    article_table(group, :warm)
    move_down 30
    text 'Kühlkiste', style: :bold, size: 14
    article_table(group, :cold)
    missing_ingredients_table(group)
  end

  def article_table(group, filter)
    table(
      [%w[Name Menge gepackt]] + table_data(@group_articles.fetch(group, []).select(&"#{filter}?".to_sym)),
      header: true, position: :center, width: bounds.width, column_widths: { 1 => 75, 2 => 66 }
    ) do
      cells.borders = [:top]

      row(0).font_style = :bold
      row(0).borders = [:bottom]

      columns(1..3).align = :right
    end
  end

  def table_data(group_articles)
    group_articles.map do |group_article|
      [
        group_article.article.packing_name,
        group_article.humanize_quantity,
        '[    ]          [    ]'
      ]
    end
  end

  def groups_info
    font('CabinSketch') do
      font_size(20) { text 'Gruß an die Küche', style: :bold }
    end
    info_text = \
      @box.groups_info.body.to_html \
          .gsub(/<div ?(.*?)>/, '') \
          .gsub(%r{</div ?(.*?)>}, '')
    text prepare_for_prawn(info_text), inline_format: true
    text "\n"
  end

  def missing_ingredients_table(group)
    return unless (missing_ingredients = @missing_ingredients[group])

    move_down 30
    text 'Fehlmengen', style: :bold, size: 14
    table(
      [%w[Name Menge gepackt]] + missing_ingredients_table_data(missing_ingredients),
      header: true, position: :center, width: bounds.width
    ) do
      cells.borders = [:top]
      row(0).font_style = :bold
      row(0).borders = [:bottom]
      column(1..2).align = :right
    end
  end

  def missing_ingredients_table_data(missing_ingredients)
    missing_ingredients.map do |missing_ingredient|
      [
        missing_ingredient.ingredient.name,
        missing_ingredient.quantity_unit.humanize,
        '[    ]          [    ]'
      ]
    end
  end
end
