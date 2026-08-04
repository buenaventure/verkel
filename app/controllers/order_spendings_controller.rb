# frozen_string_literal: true

class OrderSpendingsController < ApplicationController
  authorize_resource

  def index
    @order_spending_overview = OrderSpending.overview
  end

  def show
    @order_spending = OrderSpending.find(params[:day])
  end
end
