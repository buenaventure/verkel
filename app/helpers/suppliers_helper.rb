module SuppliersHelper
  def supplier_table_status_class(supplier)
    if (color = supplier_status_color(supplier))
      "table-#{color}"
    else
      ''
    end
  end

  def supplier_list_status_class(supplier)
    if (color = supplier_status_color(supplier))
      " list-group-item-#{color}"
    else
      ''
    end
  end

  private

  def supplier_status_color(supplier)
    return nil unless supplier.next_required_order_date
    return 'danger' if supplier.next_required_order_date <= DateTime.current
    return 'warning' if supplier.next_required_order_date <= DateTime.current + 24.hours
  end
end
