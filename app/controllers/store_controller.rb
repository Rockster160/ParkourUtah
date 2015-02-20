class StoreController < ApplicationController
  before_action :set_cart
  before_action :set_categories, only: [:edit, :new]

  def index
    @items = LineItem.all
  end

  def show_cart
  end

  def update_cart
    item = @cart.transactions.where(item_id: params[:item_id]).first
    item.update(amount: params[:new_amount])
    respond_to do |format|
      format.js
    end
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
    order = orders.where(item_id: params[:id]).first
    if order
      order.increment!(:amount)
    else
      order = Transaction.create(item_id: params[:id])
      orders << order
    end
    flash.now[:notice] = "#{order.item.title} successfully added to cart."
    respond_to do |format|
      format.js
    end
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
