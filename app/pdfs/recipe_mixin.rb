module RecipeMixin
  include RecipesHelper

  def load_fonts
    font_families.update(
      'Vollkorn' =>
        {
          normal: Rails.root.join('app/assets/fonts/Vollkorn-Regular.ttf'),
          italic: Rails.root.join('app/assets/fonts/Vollkorn-Italic.ttf'),
          bold: Rails.root.join('app/assets/fonts/Vollkorn-Bold.ttf'),
          bold_italic: Rails.root.join('app/assets/fonts/Vollkorn-BoldItalic.ttf')
        },
      'CabinSketch' =>
        {
          normal: Rails.root.join('app/assets/fonts/CabinSketch-Regular.ttf'),
          bold: Rails.root.join('app/assets/fonts/CabinSketch-Bold.ttf'),
        }
    )
    font 'Vollkorn'
  end

  def text_with_images(content)
    while (i = content.index('<img'))
      text content[0...i], inline_format: true
      content = content[i..]
      j = content.index('>')
      src = content[0..j].match(/src="(.*?)"/)[1]
      image Rails.root.join(Rails.application.config.recipes_path + src), fit: [0.8 * bounds.width, 0.8 * bounds.width], align: :center
      content = content[(j + 1)..]
    end
    text content, inline_format: true
  end

  private

  def prepare_for_prawn(html)
    html \
      .gsub(/ data-weight-factor="[0-9.]*"/, '') \
      .gsub("\n", ' ') \
      .gsub(/<h1 ?(.*?)>/, "\n<font name=\"CabinSketch\" size=\"20\">").gsub('</h1>', "</font>\n") \
      .gsub(/<h2 ?(.*?)>/, "\n<font name=\"CabinSketch\" size=\"18\">").gsub('</h2>', "</font>\n") \
      .gsub(/<h3 ?(.*?)>/, "\n<font name=\"CabinSketch\" size=\"16\">").gsub('</h3>', "</font>\n") \
      .gsub(/<h4 ?(.*?)>/, "\n<font name=\"CabinSketch\" size=\"14\">").gsub('</h4>', "</font>\n") \
      .gsub(/<h5 ?(.*?)>/, "\n<font name=\"CabinSketch\" size=\"12\">").gsub('</h5>', "</font>\n") \
      .gsub(%r{</p> *<ul>}, "\n").gsub(%r{</ul> *<p>}, '') \
      .gsub('<ul>', "\n").gsub('</ul>', '') \
      .gsub('<p>', "\n").gsub('</p>', "\n") \
      .gsub('<li>', '• ').gsub('</li>', "\n") \
      .gsub('<strong>', '<b>').gsub('</strong>', '</b>') \
      .gsub('<em>', '<i>').gsub('</em>', '</i>') \
      .gsub('<del>', '<strikethrough>').gsub('</del>', '</strikethrough>')
  end
end
