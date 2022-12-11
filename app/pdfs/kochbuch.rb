require 'prawn/measurement_extensions'

class Kochbuch < Prawn::Document
  include RecipeMixin

  def initialize(recipes)
    super(
      page_size: 'A5',
      top_margin: 17.mm,
      margin: 12.5.mm,
      bottom_margin: 17.mm
    )
    @recipes = recipes

    load_fonts

    body

    number_pages '<page>',
      {
        at: [bounds.right - 150, 0],
        align: :right,
      }
  end

  private

  def body
    @recipes.order(:name).each do |recipe|
      font('CabinSketch') do
        font_size(30) { text recipe.name, style: :bold }
      end
      font_size(20) { text "#{recipe.servings} Portionen" }
      move_down 10
      text_with_images prepare_for_prawn(markdown_to_html(recipe.content))
      start_new_page
    end
  end
end
