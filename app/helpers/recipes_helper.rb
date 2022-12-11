module RecipesHelper
  def markdown_to_html(content)
    Kramdown::Document.new(
      content,
      Rails.application.config.kramdown_options
    ).to_html.html_safe
  end
end
