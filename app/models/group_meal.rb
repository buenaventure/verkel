class GroupMeal < ApplicationRecord
  belongs_to :group
  belongs_to :meal

  enum :origin, { individual_participant: 0, chosen: 1, mandatory: 2 }
end
