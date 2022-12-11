class GroupMealParticipant < ApplicationRecord
  belongs_to :group
  belongs_to :meal
  belongs_to :participant
end
