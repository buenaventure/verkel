require 'rails_helper'

RSpec.describe PackingListsArticles, type: :model do
  describe 'PDF generation' do
    it 'generates a PDF with articles grouped by ingredient' do
      packing_lane1 = create(:packing_lane, name: 'Packstraße 1')
      packing_lane2 = create(:packing_lane, name: 'Packstraße 2')

      supplier1 = create(:supplier, name: 'Bio-Hof Müller')
      supplier2 = create(:supplier, name: 'Quarkerei Schmidt')
      supplier3 = create(:supplier, name: 'Milchhof Bauer')

      quark = create(:ingredient, name: 'Quark')
      milch = create(:ingredient, name: 'Milch')
      mehl = create(:ingredient, name: 'Mehl')

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
                        :bulk,
                        ingredient: quark,
                        supplier: supplier3,
                        name: '',
                        needs_cooling: true)
      article4 = create(:article,
                        ingredient: milch,
                        supplier: supplier2,
                        name: 'Vollmilch',
                        quantity: 1,
                        unit: 'l',
                        packing_type: :piece,
                        needs_cooling: true)
      article5 = create(:article,
                        ingredient: mehl,
                        supplier: supplier1,
                        name: 'Type 405',
                        quantity: 1,
                        unit: 'kg',
                        packing_type: :piece,
                        needs_cooling: false)

      group1 = create(:group, name: 'Gruppe A', packing_lane: packing_lane1)
      group2 = create(:group, name: 'Gruppe B', packing_lane: packing_lane1)
      group3 = create(:group, name: 'Gruppe C', packing_lane: packing_lane2)

      box = create(:box)

      create(:group_box_article, group: group1, box:, article: article1, quantity: 2)
      create(:group_box_article, group: group1, box:, article: article2, quantity: 3)
      create(:group_box_article, group: group2, box:, article: article1, quantity: 1)
      create(:group_box_article, group: group2, box:, article: article3, quantity: 500)
      create(:group_box_article, group: group3, box:, article: article4, quantity: 2)
      create(:group_box_article, group: group3, box:, article: article5, quantity: 1)

      pdf = described_class.new(box, filter: nil)

      output_path = Rails.root.join('tmp/packing_lists_articles_example.pdf')
      File.binwrite(output_path, pdf.render)

      expect(File.exist?(output_path)).to be true
      expect(File.size(output_path)).to be_positive
    end
  end
end
