# frozen_string_literal: true

class GroupSpendingsController < ApplicationController
  authorize_resource

  def index
    @group_spending_overview = GroupSpending.overview
  end

  def show
    @group_spending = GroupSpending.find(params[:group_id])
  end
end
