# frozen_string_literal: true

class GroupBoxCost < ApplicationRecord
  belongs_to :group
  belongs_to :box

  scope :final, -> { where(is_final: true) }

  def self.totals_by_group
    group(:group_id).sum(:total_cost)
  end

  def self.final_totals_by_group
    final.group(:group_id).sum(:total_cost)
  end

  def self.indexed_by_group_and_box
    includes(:box).index_by { |cost| [cost.group_id, cost.box_id] }
  end
end
