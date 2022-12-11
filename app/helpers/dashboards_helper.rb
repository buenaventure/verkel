module DashboardsHelper
  def packing_lane_box_status_color(packing_lane_box)
    if packing_lane_box.deficiency?
      'danger'
    elsif packing_lane_box.surplus?
      'warning'
    else
      'success'
    end
  end
end
