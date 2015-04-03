class StoreController < ApplicationController
  before_action :set_cart
  before_action :set_categories, only: [:edit, :new]
  before_action :validate_admin, only: [:generate_keys, :email_keys]

  def index
    @items = LineItem.select { |item| !(item.hidden) }.sort_by { |order| order.item_order }.reverse
  end

  def show_cart
  end

  def generate_keys
    @hidden = LineItem.select { |l| l.hidden == true }.sort_by { |s| s.created_at }.reverse
  end

  def email_keys
    keys = []
    item = LineItem.find(params[:key_type])
    while keys.length < params[:how_many].first.to_i
      keys << item.redemption_keys.create.key
      keys.compact
    end
    ::KeyGenMailerWorker.perform_async(keys, item.title)
    redirect_to dashboard_path, notice: "Got it! An email will be sent to you shortly containing the requested keys."
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
    redirect_to dashboard_path
  end

  def create
    if LineItem.create(item_params)
      flash[:notice] = "Item successfully created."
    else
      flash[:alert] = "There was an error creating the item."
    end
    redirect_to dashboard_path
  end

  def payment
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
    key = RedemptionKey.where(key: params[:redemption_key]).first
    item = key.item if key.redeemed == false
    if item && @cart.transactions.map { |items| items.redeemed_token }.exclude?(params[:redemption_key])
      @cart.transactions << @order = Transaction.create(item_id: item.id, redeemed_token: params[:redemption_key])
    else
      @order = nil
    end

    respond_to do |format|
      format.js
    end
  end

  def charge
    if current_user.cart.price > 0
      unless current_user.stripe_id
        Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
        token = params[:stripeToken]
        customer = Stripe::Customer.create(
          :source => token,
          :description => params[:stripeEmail]
        )
        current_user.update(stripe_id: customer.id)
      end
    end
    purchase_cart

    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to charges_path
  end

  private

  def purchase_cart
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
    unless current_user.address.is_valid?
      flash[:alert] = "Please fill out your shipping information before making an order."
    else
      if current_user.cart.price > 0
        charge = Stripe::Charge.create(
          :amount   => current_user.cart.total,
          :currency => "usd",
          :customer => current_user.stripe_id
        )
      end
      if !(charge) || charge.status == "succeeded"
        current_user.cart.transactions.each do |order|
          line_item = LineItem.find(order.item_id)
          if RedemptionKey.redeem(order.redeemed_token)
            current_user.update(credits: (current_user.credits + (order.amount * line_item.credits)))
          end
        end
        current_user.cart = Cart.create
        # TODO Send email to user
        # TODO send email to Justin, if shipping is necessary.
        flash[:notice] = "Cart was successfully purchased."
      else
        flash[:alert] = "There was an error with your request."
      end
    end
    redirect_to edit_user_registration_path
  end

  def item_params
    params[:line_item][:cost_in_pennies] = (params[:line_item][:cost].to_i * 100).round.to_s
    params.require(:line_item).permit(:description, :title, :display, :cost_in_pennies, :category, :hidden, :credits)
  end

  def set_categories
    @categories = ["Class", "Goods"]
  end

  def set_cart
    validate_signed_in # Temporary until session carts are fixed....
    @cart = current_user.cart if user_signed_in?
  end

  def validate_signed_in
    unless current_user
      redirect_to new_user_session_path, alert: "Store is currently only available to signed in users. Sorry!"
    end
  end

  def validate_admin
    unless current_user && current_user.is_admin?
      redirect_to root_path, alert: "You do not have permission to access this page."
    end
  end

  def publicly_unavailable
    unless current_user && current_user.is_admin?
      redirect_to coming_soon_path
    end
  end
end
