class ExtraIngredient < ApplicationRecord
  include NormalizedQuantityUnit

  belongs_to :group
  belongs_to :box
  belongs_to :ingredient

  def group_box
    GroupBox.find_by(group:, box:)
  end

  def self.breadcrumb_index_on_parent
    true
  end

  def to_s
    "Extra #{ingredient}"
  end

  private

  def breadcrumb_parent
    group_box
  end
end
