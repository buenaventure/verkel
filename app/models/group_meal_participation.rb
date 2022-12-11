class GroupMealParticipation < ApplicationRecord
  belongs_to :group
  belongs_to :meal
  belongs_to :participant

  def to_s
    'Mahlzeit-Teilnahme'
  end

  private

  def breadcrumb_parent
    group
  end
end
