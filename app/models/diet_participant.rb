class DietParticipant < ApplicationRecord
  belongs_to :diet
  belongs_to :participant
end
