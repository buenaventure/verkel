class Group < ApplicationRecord
  belongs_to :packing_lane, optional: true

  has_many :group_meals
  has_many :group_boxes
  has_many :group_meal_participations, dependent: :destroy
  has_many :group_meal_participants
  has_many :participants, dependent: :restrict_with_error
  has_rich_text :notes

  validates :name, uniqueness: true, presence: true
  validates :internal_name, uniqueness: true, unless: ->(group) { group.internal_name.blank? }

  before_save do
    self.internal_name = nil if internal_name.blank?
  end

  def to_s
    display_name
  end

  def display_name
    if internal_name.nil?
      name
    else
      "#{internal_name} (#{name})"
    end
  end
end
