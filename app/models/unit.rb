class Unit < ApplicationRecord
  validates :name, uniqueness: true
end
