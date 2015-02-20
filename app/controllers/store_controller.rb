class StoreController < ApplicationController
  before_action :set_cart
  before_action :set_categories, only: [:edit, :new]

  def index
    @items = LineItem.all
  end

  def new
    @item = LineItem.new
  end

  def edit
    @item = LineItem.find(params[:id])
  end

  def update
    LineItem.find(params[:id]).update(item_params)
    redirect_to store_path
  end

  def create
    LineItem.create(item_params)
    redirect_to store_path
  end

  def add_to_cart
    orders = current_user.cart.transactions
    item = orders.where(item_id: params[:id]).first
    if item
      item.increment!(:amount)
    else
      orders << Transaction.create(item_id: params[:id])
    end
    head :ok # Update the Cart?
  end

  private

  def item_params
    params.require(:line_item).permit(:description, :title, :display, :cost, :category)
  end

  def set_categories
    @categories = ["Other", "Shoes", "Shirts", "Stuff"]
  end

  def set_cart
    @cart = current_user.cart if user_signed_in?
  end
end
