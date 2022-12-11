require 'prawn/measurement_extensions'

class OrderDocument < Prawn::Document
  include UnitsHelper
  include RecipeMixin

  def initialize(order)
    super(page_size: 'A4')
    @order = order
    load_fonts
    body
  end

  def filename
    "#{@order.coverage.begin.to_date}_#{@order.supplier.name.parameterize}.pdf"
  end

  private

  def body
    text @order.supplier.name, size: 24
    move_down 1.cm
    text @order.supplier.address
    move_down 1.cm

    text "Lieferzeitpunkt: #{I18n.l @order.coverage.begin, format: :short}"

    table([%w[Name Geb.gr. Geb.pr. Best.menge Ges.menge Ges.pr.]] + table_data, header: true, width: bounds.width) do
      cells.borders = [:top]

      row(0).font_style = :bold
      row(0).borders = [:bottom]
      row(-1).font_style = :bold

      columns(1..-1).align = :right
    end
  end

  def table_data
    @order.order_articles.non_zero.map do |order_article|
      [
        order_article.article.ordering_name,
        order_article.article.quantity_unit.humanize,
        "#{number_with_delimiter order_article.article.price}\u00A0€",
        number_with_delimiter(order_article.quantity_ordered),
        order_article.quantity_unit_ordered.humanize,
        "#{number_with_delimiter order_article.price_ordered}\u00A0€"
      ]
    end + \
      [[
        'Summe',
        nil,
        nil,
        nil,
        nil,
        "#{number_with_delimiter @order.price_ordered}\u00A0€"
      ]]
  end
end
