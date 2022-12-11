require 'prawn/measurement_extensions'

class InventoryList < Prawn::Document
  include UnitsHelper
  include RecipeMixin

  FOOTER_SIZE = 10.mm
  MARGIN = 12.5.mm

  def initialize
    super(
      page_size: 'A4',
      top_margin: MARGIN + FOOTER_SIZE,
      margin: MARGIN,
      bottom_margin: MARGIN + FOOTER_SIZE)
    @articles = Article.lexical
    load_fonts
    body
  end

  def filename
    "#{I18n.l(Time.zone.now, format: :sortable).parameterize}-inventurliste.pdf"
  end

  private

  def body
    first_page = page_number
    font('CabinSketch') do
      font_size(20) { text 'Inventurliste', style: :bold }
    end
    table(
      [%w[Artikel Geb.gr. Bestand Gezählt]] + table_data,
      header: true, position: :center, width: bounds.width,
      column_widths: { 1 => 75, 2 => 65, 3 => 60 }
    ) do
      cells.borders = [:top]

      row(0).font_style = :bold
      row(0).borders = [:bottom]

      columns(1..3).align = :right
    end
    total_pages = (first_page..page_number).size
    (first_page..page_number).each_with_index do |i, page|
      go_to_page i
      canvas do
        bounding_box(
          [MARGIN, MARGIN + FOOTER_SIZE],
          width: bounds.right - 2 * MARGIN, height: FOOTER_SIZE
        ) do
          float { text "Inventurliste Stand #{I18n.l Time.zone.now}", size: 10 }
          text "Seite #{page + 1} / #{total_pages}", size: 10, valign: :bottom, align: :right
        end
      end
    end
  end

  def table_data
    @articles.map do |article|
      [
        article.packing_name,
        article.quantity_unit.humanize,
        article.packing_type == 'bulk' ? article.quantity_unit_stock.humanize : number_with_delimiter(article.stock),
        ''
      ]
    end
  end
end
