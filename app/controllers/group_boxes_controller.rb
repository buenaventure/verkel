class GroupBoxesController < ApplicationController
  authorize_resource
  before_action :set_group_box

  def show; end

  private

  def set_group_box
    @group_box = GroupBox.find_by(group_id: params[:id], box_id: params[:box_id])
  end
end
