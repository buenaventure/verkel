module NormalizedQuantityUnit
  extend ActiveSupport::Concern

  # Spellings normalize_unit rewrites to an allowed unit before validation.
  UNIT_ALIASES = { 'kg' => 'g', 'l' => 'ml', 'tl' => 'TL', 'el' => 'EL' }.freeze

  included do
    before_validation :normalize_unit
    validates :unit, presence: true, inclusion: {
      in: -> { NormalizedQuantityUnit.allowed_units },
      message: '%<value>s ist keine erlaubte Einheit'
    }
    validates :quantity, numericality: true
  end

  def self.allowed_units
    Unit.pluck(:name) + %w[g ml]
  end

  # Every unit a user may type, including the aliases that normalize to an allowed unit.
  def self.accepted_units
    allowed = allowed_units
    allowed + UNIT_ALIASES.select { |_from, to| allowed.include?(to) }.keys
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
