require 'rails_helper'

RSpec.describe ArticlePackingPlanner, type: :model do
  context 'minimum demand fulfilling amount equals largest article quantity' do
    let(:group) { create(:group) }
    let(:box) { create(:box) }
    let(:ingredient) { create(:ingredient, name: 'Würstchen') }
    let(:unit) { 'Stück' }
    let!(:articles) { [10, 20, 40].map { |n| create(:article, ingredient:, quantity: n, unit:, packing_type: :piece) } }
    subject { described_class.new }
    it 'plans 1x20 2x10 for 32' do
      subject.instance_variable_set :@demands, { IngredientUnit.new(ingredient.id, unit) => [
        GroupBoxIngredientUnitCache.new(group:, box:, ingredient:, quantity: 32, unit:)
      ] }
      subject.run
      expect(GroupBoxArticle.find_by(group:, box:, article: articles[0]).quantity).to eq 2
      expect(GroupBoxArticle.find_by(group:, box:, article: articles[1]).quantity).to eq 1
    end
  end
end
