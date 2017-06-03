class LineItemsController < ApplicationController
  before_action :validate_admin
  before_action :set_categories, only: [ :edit, :new ]
  before_action :set_hidden, only: [ :edit, :new ]

  def index
    @items = LineItem.order(item_order: :asc)
  end

  def new
    @item = LineItem.new
  end

  def create
    if item = LineItem.create(item_params)
      flash[:notice] = "Item successfully created."
    else
      flash[:alert] = "There was an error creating the item."
    end
    redirect_to dashboard_path
  end

  def edit
    @item = LineItem.find(params[:id])
  end

  def update
    item = LineItem.find(params[:id])
    if item.update(item_params)
      flash[:notice] = "Item successfully updated."
    else
      flash[:alert] = "There was an error updating the item."
    end
    puts "#{item.reload.attributes}".colorize(:red)
    redirect_to dashboard_path
  end

  def update_position
    @item = LineItem.find(params[:id])
    @item.update(item_order: params["line_item"]["line_item_position"].to_i)
    respond_to do |format|
      format.json { render json: @item }
    end
  end

  def destroy
    LineItem.find(params[:id]).destroy
    redirect_to dashboard_path, notice: "Item successfully destroyed."
  end

  private

  def validate_admin
    unless current_user && current_user.is_admin?
      redirect_to root_path, alert: "You do not have permission to access this page."
    end
  end

  def set_categories
    @categories = ["Class", "Clothing", "Accessories", "Gift Card", "Other", "Coupon", "Redemption"]
  end

  def set_hidden
    @hidden_items = LineItem.where(hidden: true).reorder(created_at: :desc).map { |item| [item.title, item.id] }
  end

  def item_params
    params[:line_item][:locations] = params[:line_item][:location_ids].try(:keys)&.join(",")
    params[:line_item][:instructors] = params[:line_item][:instructor_ids].try(:keys)&.join(",")
    params.require(:line_item).permit(
      :description,
      :title,
      :display,
      :cost_in_pennies,
      :cost_in_dollars,
      :category,
      :hidden,
      :credits,
      :color,
      :size,
      :is_subscription,
      :taxable,
      :is_full_image,
      :show_text_as_image,
      :redemption_item_id,
      :instructors,
      :locations,
      :time_range_start,
      :time_range_end,
      :bundle_cost,
      :bundle_amount
    )
  end

end
