class PlanItemsController < ApplicationController
  before_action :validate_admin

  def index
    @plans = PlanItem.order(created_at: :desc)
  end

  def new
    @plan = PlanItem.new
    render :form
  end

  def edit
    @plan = PlanItem.find(params[:id])
    render :form
  end

  def update
    @plan = PlanItem.find(params[:id])

    if @plan.update(plan_item_params)
      redirect_to plan_items_path
    else
      render :form
    end
  end

  def create
    @plan = PlanItem.new

    if @plan.update(plan_item_params)
      redirect_to plan_items_path
    else
      render :form
    end
  end

  private

  def plan_item_params
    params.require(:plan_item).permit(
      :name,
    ).tap do |whitelist|
      whitelist[:discount_items] = params.dig(:plan_item, :discount_items)&.map(&:permit!)
      whitelist[:free_items] = params.dig(:plan_item, :free_items)&.map(&:permit!)
    end
  end
end
