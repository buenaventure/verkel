# frozen_string_literal: true

module Seeds
  module Helpers
    module_function

    def find_or_create_user!(email:, password:, role:)
      User.find_or_create_by!(email:) do |user|
        user.password = password
        user.role = role
      end
    end

    def find_or_create_ingredient!(name:, **attrs)
      Ingredient.find_or_create_by!(name:) do |ingredient|
        ingredient.assign_attributes(attrs)
      end
    end

    def upsert_article!(ingredient:, supplier:, **attrs)
      article = Article.find_or_initialize_by(ingredient:, supplier:)
      article.assign_attributes(
        name: '',
        stock: 100,
        priority: 0,
        needs_cooling: false,
        packing_type: :piece,
        **attrs
      )
      article.save!
      article
    end

    def create_group_participants!(group:, meal:, ages:)
      ages.map do |age|
        participant = Participant.create!(age:, group:)
        GroupMealParticipation.create!(group:, meal:, participant:)
        participant
      end
    end

    def recalculate!
      GroupBoxIngredientUnitCache.do_calculate
      ArticlePackingPlanner.do_calculate
    end
  end
end
