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

  def purchase
    if current_user.buy_shopping_cart == "Ok"
      current_user.cart = Cart.create
      flash[:notice] = "Cart successfully purchased"
      redirect_to root_path
    else
      # This should check for various errors and report accurately.
      flash[:alert] = "There was a problem with your request."
      redirect_to show_cart_path
    end
  end

  def new
    @item = LineItem.new
  end

  def edit
    @item = LineItem.find(params[:id])
  end

  def update
    if LineItem.find(params[:id]).update(item_params)
      flash[:notice] = "Item successfully updated."
    else
      flash[:alert] = "There was an error updating the item."
    end
    redirect_to store_path
  end

  def create
    if LineItem.create(item_params)
      flash[:notice] = "Item successfully created."
    else
      flash[:alert] = "There was an error creating the item."
    end
    redirect_to store_path
  end

  def add_to_cart
    # User.last.update(class_pass: User.last.class_pass + 5)
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
