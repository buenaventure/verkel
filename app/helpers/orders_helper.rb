module OrdersHelper
  def order_table_status_class(order)
    if (color = order_status_color(order))
      "table-#{color}"
    else
      ''
    end
  end

  def order_list_status_class(order)
    if (color = order_status_color(order))
      " list-group-item-#{color}"
    else
      ''
    end
  end

  private

  def order_status_color(order)
    return 'success' if order.stored?
    return 'info' if order.delivered?

    if order.planned?
      return 'danger' if order.latest_order_date <= DateTime.current
      return 'warning' if order.latest_order_date <= DateTime.current + 24.hours
    end
    return 'danger' if order.coverage_begin <= DateTime.current
    return 'warning' if order.coverage_begin <= DateTime.current + 24.hours
  end
end
