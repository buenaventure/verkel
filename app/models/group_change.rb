class GroupChange < ApplicationRecord
  belongs_to :participant
  belongs_to :group

  include DateTimeRange
  date_time_range :timeframe

  validates :timeframe_end,
            numericality: { greater_than: :timeframe_begin, message: 'muss nach dem Beginn liegen' }

  def to_s
    "Kochgruppenänderung zu #{group}"
  end

  def save(*args)
    super(*args)
  rescue ActiveRecord::StatementInvalid => e
    raise e unless e.cause.is_a? PG::ExclusionViolation

    errors.add(:timeframe_begin, 'überlappt sich mit einer anderen Änderung')
    errors.add(:timeframe_end, 'überlappt sich mit einer anderen Änderung')
    false
  end

  private

  def breadcrumb_parent
    participant
  end
end
