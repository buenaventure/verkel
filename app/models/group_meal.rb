class GroupMeal < ApplicationRecord
  belongs_to :group
  belongs_to :meal
end
