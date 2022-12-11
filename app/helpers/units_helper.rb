module UnitsHelper
  include ActionView::Helpers::NumberHelper

  def humanize_unit(quantity, unit)
    QuantityUnit.new(quantity, unit).humanize
  end

  def display_unit(quantity, unit)
    QuantityUnit.new(quantity, unit).display
  end

  def humanize_units(quantity_units)
    quantity_units.map(&:humanize).join(', ')
  end

  def units_sum(quantity_units)
    QuantityUnit.sum(quantity_units)
  end

  def humanize_units_sum(quantity_units)
    humanize_units units_sum quantity_units
  end
end
