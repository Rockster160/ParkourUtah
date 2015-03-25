class StoreController < ApplicationController
  before_action :set_cart
  before_action :set_categories, only: [:edit, :new]
  before_action :validate_admin, only: [:generate_keys, :email_keys]

  def index
    @items = LineItem.select { |item| !(item.hidden) }.sort_by { |order| order.item_order }.reverse
  end

  def show_cart
  end

  def purchase
    unless current_user.payment_id == nil
      if current_user.buy_shopping_cart == "Ok"
        current_user.cart.transactions.each do |item|
          line_item = LineItem.find(item.item_id)
          if RedemptionKey.redeem(item.redeemed_token)
            current_user.update(credits: (current_user.credits + (item.amount * line_item.credits)))
          end
        end
        current_user.cart = Cart.create
        redirect_to root_path, notice: "Cart successfully purchased"
      else
        # This should check for various errors and report accurately.
        redirect_to store_path, alert: "There was a problem with your request."
      end
    else
      redirect_to edit_user_registration_path, alert: "Please fill out your billing information before you purchase any items."
    end
  end

  def generate_keys
  end

  def email_keys
    keys = []
    params[:how_many].first.to_i.times do
      keys << RedemptionKey.create(redemption: params[:key_type]).key
    end
    ::KeyGenMailerWorker.perform_async(keys, params[:key_type])
    redirect_to :back, notice: "Got it! An email will be sent to you shortly containing the requested keys."
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

  def update_cart
    orders = @cart.transactions
    order = orders.where(item_id: params[:item_id]).first
    if params[:new_amount]
      params[:new_amount] ||= "0"
      if params[:new_amount].to_i <= 0
        order.destroy!
      else
        order.update(amount: params[:new_amount])
      end
    else
      if order
        order.increment!(:amount)
      else
        order = Transaction.create(item_id: params[:item_id])
        orders << order
        @order = order
      end
      flash.now[:notice] = "#{order.item.title} successfully added to cart."
    end
    respond_to do |format|
      format.js
    end
  end

  def redeem
    item = RedemptionKey.lookup(params[:redemption_key])
    if item && @cart.transactions.map { |items| items.redeemed_token }.exclude?(params[:redemption_key])
      @cart.transactions << @order = Transaction.create(item_id: item.id, redeemed_token: params[:redemption_key])
    else
      @order = nil
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def item_params
    params.require(:line_item).permit(:description, :title, :display, :cost, :category)
  end

  def set_categories
    @categories = ["Other", "Shoes", "Shirts", "Classes", "Stuff"]
  end

  def set_cart
    validate_user # Temporary until session carts are fixed....
    @cart = current_user.cart if user_signed_in?
  end

  def validate_user
    unless current_user && current_user.is_admin?
      redirect_to new_user_session_path, alert: "Store is currently only available to signed in users. Sorry!"
    end
  end

  def validate_admin
    unless current_user && current_user.is_admin?
      redirect_to root_path, alert: "You do not have permission to access this page."
    end
  end
end
