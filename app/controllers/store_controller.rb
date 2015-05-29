class StoreController < ApplicationController
  before_action :set_cart
  before_action :set_categories, only: [:edit, :new]
  before_action :validate_admin, only: [:generate_keys, :email_keys]

  def index
    @items = {}
    LineItem.select { |item| !(item.hidden) }.each do |item|
      dest = case item.category
      when "Class" then :classes
      when "Clothing" then :clothing
      when "Accessories" then :accessories
      else :other
      end
      @items[dest] ||= []
      @items[dest] << item
    end
  end

  def show_cart
  end

  def generate_keys
    @hidden = LineItem.select { |l| l.hidden == true }.sort_by { |s| s.created_at }.reverse
  end

  def unsubscribe
    user = User.find(params[:id])
    if user.update(stripe_subscription: false)
      redirect_to edit_user_registration_path, notice: 'Successfully Unsubscribed'
    else
      redirect_to edit_user_registration_path, alert: 'There was an error.'
    end
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

  def destroy
    LineItem.find(params[:id]).destroy
    redirect_to dashboard_path, notice: "Item successfully destroyed."
  end

  def new
    @item = LineItem.new
  end

  def edit
    @item = LineItem.find(params[:id])
  end

  def items
    @items = LineItem.all
  end

  def update
    if LineItem.find(params[:id]).update(item_params)
      flash[:notice] = "Item successfully updated."
    else
      flash[:alert] = "There was an error updating the item."
    end
    redirect_to dashboard_path
  end

  def update_item_position
    @item = LineItem.find(params[:id])
    @item.update(item_order: params["line_item"]["line_item_position"].to_i)
    respond_to do |format|
      format.json { render json: @item }
    end
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
    item_title = if params[:item_id]
      item = LineItem.find(params[:item_id])
      item.title
    else
      params[:item_name]
    end
    size = params[:size] ? "#{params[:size]} " : ""
    color = params[:color] ? "#{params[:color]} " : ""
    name = "#{size}#{color}#{item_title}"

    orders = @cart.transactions
    order = orders.where(order_name: name).first
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
        order = Transaction.create(item_id: item.id, order_name: name)
        orders << order
        @order = order
      end
      flash.now[:notice] = "#{order.order_name} successfully added to cart."
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
    unless current_user.address && current_user.address.is_valid?
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
          if line_item.is_subscription?
            current_user.update(stripe_subscription: true)
            current_user.unlimited_subscriptions.create
          end
        end
        ItemsPurchasedMailerWorker.perform_async(current_user.cart.id, "rocco11nicholls@gmail.com")
        ItemsPurchasedMailerWorker.perform_async(current_user.cart.id, current_user.email)
        ItemsPurchasedMailerWorker.perform_async(current_user.cart.id, ENV["PKUT_EMAIL"])
        current_user.carts.create
        flash[:notice] = "Cart was successfully purchased."
      else
        flash[:alert] = "There was an error with your request."
      end
    end
    redirect_to edit_user_registration_path
  end

  def item_params
    params[:line_item][:cost_in_pennies] = (params[:line_item][:cost_in_dollars].to_f * 100).round.to_s
    params.require(:line_item).permit(
      :description, :title, :display,
      :cost_in_pennies, :category, :hidden, :credits,
      :color, :size, :is_subscription, :taxable
    )
  end

  def set_categories
    @categories = ["Class", "Clothing", "Accessories", "Other", "Coupon"]
  end

  def set_cart
    # validate_signed_in # Temporary until session carts are fixed.... TODO
    if user_signed_in?
      @cart = current_user.cart
    else
      redirect_to new_user_session_path, alert: "Store is currently only available to signed in users. Sorry!", data: { no_turbolink: true }
    end
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
