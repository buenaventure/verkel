module NormalizedQuantityUnit
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_unit
    validates :unit, presence: true, inclusion: {
      in: -> { Unit.pluck(:name) + %w[g ml] },
      message: '%<value>s ist keine erlaubte Einheit'
    }
    validates :quantity, numericality: true
  end

  def quantity_unit
    QuantityUnit.new(quantity, unit)
  end

  private

  def normalize_unit
    case unit
    when 'kg'
      self.unit = 'g'
      self.quantity *= 1000
    when 'l'
      self.unit = 'ml'
      self.quantity *= 1000
    when 'tl' then self.unit = 'TL'
    when 'el' then self.unit = 'EL'
    end
  end
end
