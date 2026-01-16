class QuantityUnits
  def initialize(quantity_units = [])
    raise 'expected quantity_units to be an Array' unless quantity_units.is_a?(Array)
    unless quantity_units.all? { |qu| qu.is_a?(QuantityUnit) }
      raise 'expected quantity_units to be an Array of QuantityUnit'
    end

    @quantity_units = quantity_units
  end

  attr_reader :quantity_units

  delegate :each, :map, to: :quantity_units

  def sum
    self.class.new(
      @quantity_units
      .group_by(&:unit)
      .map do |unit, qu|
        QuantityUnit.new(qu.sum(&:quantity), unit)
      end
    )
  end

  def sum_str
    sum(@quantity_units).map(&:humanize).join(', ')
  end

  def inspect
    "<QuantityUnits #{@quantity_units.inspect}>"
  end

  def +(other)
    self.class.new(quantity_units + other.quantity_units)
  end

  def -(other)
    self.class.new(quantity_units + other.quantity_units.map { |qu| qu * -1 }).sum
  end

  def to_ary
    @quantity_units
  end

  def humanize
    @quantity_units.map(&:humanize).join(', ')
  end
end
