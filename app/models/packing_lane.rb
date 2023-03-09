class PackingLane < ApplicationRecord
  has_many :groups, dependent: :restrict_with_error
  has_many :packing_lane_article_stocks, dependent: :destroy

  validates :name, uniqueness: true, presence: true

  def to_s
    name
  end
end
