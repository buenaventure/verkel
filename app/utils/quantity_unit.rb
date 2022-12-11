QuantityUnit = Struct.new(:quantity, :unit) do
  include ActionView::Helpers::NumberHelper

  def humanize
    if quantity.abs >= 1000
      case unit
      when 'g' then QuantityUnit.new(quantity / 1000, 'kg').display
      when 'ml' then QuantityUnit.new(quantity / 1000, 'l').display
      else display
      end
    else
      display
    end
  end

  def display
    "#{number_with_precision(quantity, precision: 2, delimiter: ' ')}\u00A0#{unit}"
  end

  def *(other)
    QuantityUnit.new(quantity * other, unit)
  end

  def inspect
    "<#{quantity.inspect}\u00A0#{unit.inspect}>"
  end

  def self.sum(quantity_units)
    QuantityUnits.new(quantity_units).sum
  end

  def self.sum_str(quantity_units)
    QuantityUnits.new(quantity_units).sum_str
  end
end
