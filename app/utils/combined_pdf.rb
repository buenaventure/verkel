class CombinedPdf
  def render
    combined_pdf = CombinePDF.new
    pdfs.each do |pdf|
      combined_pdf << CombinePDF.parse(pdf.render)
    end
    combined_pdf.to_pdf
  end
end
