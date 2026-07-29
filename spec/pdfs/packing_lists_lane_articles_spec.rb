require 'rails_helper'

RSpec.describe PackingListsLaneArticles, type: :model do
  describe 'PDF generation' do
    it 'generates a PDF with articles grouped by ingredient and one row per packing lane' do
      packing_lane1 = create(:packing_lane, name: 'Packstraße 1')
      packing_lane2 = create(:packing_lane, name: 'Packstraße 2')

      supplier1 = create(:supplier, name: 'Bio-Hof Müller')
      supplier2 = create(:supplier, name: 'Quarkerei Schmidt')
      supplier3 = create(:supplier, name: 'Milchhof Bauer')

      quark = create(:ingredient, name: 'Quark')
      milch = create(:ingredient, name: 'Milch')

      article1 = create(:article,
                        ingredient: quark,
                        supplier: supplier1,
                        name: 'Magerstufe',
                        quantity: 500,
                        unit: 'g',
                        packing_type: :piece,
                        needs_cooling: true)
      article2 = create(:article,
                        ingredient: quark,
                        supplier: supplier2,
                        name: 'Vollfett',
                        quantity: 250,
                        unit: 'g',
                        packing_type: :piece,
                        needs_cooling: true)
      article3 = create(:article,
                        ingredient: milch,
                        supplier: supplier3,
                        name: 'Vollmilch',
                        quantity: 1,
                        unit: 'l',
                        packing_type: :piece,
                        needs_cooling: true)

      group1 = create(:group, name: 'Gruppe A', packing_lane: packing_lane1)
      group2 = create(:group, name: 'Gruppe B', packing_lane: packing_lane2)

      box = create(:box)

      create(:group_box_article, group: group1, box:, article: article1, quantity: 2)
      create(:group_box_article, group: group2, box:, article: article1, quantity: 3)
      create(:group_box_article, group: group1, box:, article: article2, quantity: 1)
      create(:group_box_article, group: group2, box:, article: article3, quantity: 2)

      create(:packing_lane_article_stock, packing_lane: packing_lane1, article: article1, box:, quantity: 1)
      create(:missing_ingredient, group: group1, box:, ingredient: quark, quantity: 5, unit: 'g')

      pdf = described_class.new(box, filter: nil)

      output_path = Rails.root.join('tmp/packing_lists_lane_articles_example.pdf')
      File.binwrite(output_path, pdf.render)

      expect(File.exist?(output_path)).to be true
      expect(File.size(output_path)).to be_positive

      # Two articles of the same ingredient (Quark) share a page (no page break between
      # them), while a different ingredient (Milch) starts a new page.
      expect(pdf.page_count).to eq 2
    end
  end
end
