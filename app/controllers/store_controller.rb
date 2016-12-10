class StoreController < ApplicationController
  before_action :set_cart
  before_action :set_categories, only: [:edit, :new]
  before_action :set_hidden, only: [:edit, :new]
  before_action :validate_admin, only: [:generate_keys, :email_keys]

  def index
    @items = {}
    LineItem.select { |item| !(item.hidden) }.each do |item|
      dest = case item.category
      when "Class" then :classes
      when "Clothing" then :clothing
      when "Accessories" then :accessories
      when "Gift Card" then :gift_card
      else :other
      end
      @items[dest] ||= []
      @items[dest] << item
    end
  end

  def show_cart
  end

  def generate_keys
    @hidden = LineItem.where(hidden: true).reorder(created_at: :desc)
  end

  def unsubscribe
    athlete = Dependent.find(params[:id])
    if athlete.subscription.update(auto_renew: false)
      redirect_to edit_user_registration_path, notice: 'Successfully Unsubscribed'
    else
      redirect_to edit_user_registration_path, notice: 'There was an error unsubscribing.'
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
    if item = LineItem.create(item_params)
      flash[:notice] = "Item successfully created."
    else
      flash[:alert] = "There was an error creating the item."
    end
    redirect_to dashboard_path
  end

  def payment
  end

  def update_cart
    if params[:delete_all]
      @cart.transactions.destroy_all
    else
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
        # flash.now[:notice] = "#{order.order_name} successfully added to cart."
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def redeem
    key = RedemptionKey.where(key: params[:redemption_key]).first
    if key.present?
      item = key.item if key.redeemed == false
      if item && @cart.transactions.map { |items| items.redeemed_token }.exclude?(params[:redemption_key])
        @cart.transactions << @order = Transaction.create(item_id: item.id, redeemed_token: params[:redemption_key])
      else
        @order = nil
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def charge
    unless @cart.items.count > 0
      redirect_to store_path, alert: "You can't checkout unless you have items in your cart."
      return false
    end
    @cart.update(email: params[:stripeEmail]) if params[:stripeEmail]
    if @cart.price == 0
      unless user_signed_in?
        categories = @cart.items.map(&:category).uniq
        unless categories.count == 1 && categories.first == "Gift Card"
          redirect_to store_path, alert: "You must be registered and signed in to purchase accessories or credits."
        end
      end
      purchase_cart
    else
      if user_signed_in?
        unless current_user.stripe_id
          customer = create_customer
          current_user.update(stripe_id: customer.id) if customer
        end
        purchase_cart if current_user.stripe_id
      else
        categories = @cart.items.map(&:category).uniq
        if categories.count == 1 && categories.first == "Gift Card"
          customer = create_customer
          session["stripe_id"] = customer.id
          purchase_cart
        else
          redirect_to store_path, alert: "You must be registered and signed in to purchase accessories or credits."
        end
      end
    end
  end

  private

  def create_customer
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
    token = params[:stripeToken]
    customer = Stripe::Customer.create(
      :source => token,
      :description => params[:stripeEmail]
    )
    customer
  end

  def create_charge
    stripe_charge = nil
    if @cart.price > 0
      if user_signed_in?
        stripe_id = current_user.stripe_id
      else
        stripe_id = session["stripe_id"]
      end
      begin
        stripe_charge = Stripe::Charge.create(
          :amount   => @cart.total,
          :currency => "usd",
          :customer => stripe_id
        )
      rescue
        stripe_charge = false
      end
    end
    order_success = stripe_charge.nil? || stripe_charge.try(:status) == "succeeded"
    if order_success
      @cart.transactions.each do |order|
        line_item = LineItem.find(order.item_id)
        if RedemptionKey.redeem(order.redeemed_token)
          current_user.update(credits: (current_user.credits + (order.amount * line_item.credits))) if user_signed_in?
        end
        if line_item.is_subscription? && user_signed_in?
          current_user.update(stripe_subscription: true, subscription_cost: line_item.cost_in_pennies)
          current_user.update(unassigned_subscriptions_count: current_user.unassigned_subscriptions_count + order.amount)
        end
      end
    else
      @stripe_error = stripe_charge.try(:failure_message)
      CustomLogger.log("Stripe Error: \e[31m#{stripe_charge}\e[0m", current_user, nil)
    end
    return order_success
  end

  def purchase_cart
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']

    if user_signed_in?
      if current_user.address && current_user.address.is_valid?
        if create_charge
          ItemsPurchasedMailerWorker.perform_async(current_user.cart.id, "rocco11nicholls@gmail.com")
          ItemsPurchasedMailerWorker.perform_async(current_user.cart.id, @cart.email) unless Rails.env.development?
          ItemsPurchasedMailerWorker.perform_async(current_user.cart.id, ENV["PKUT_EMAIL"]) unless Rails.env.development?
          current_user.carts.create
          flash[:notice] = "Cart was successfully purchased."
        else
          flash[:alert] = @stripe_error.presence || "There was an error with your request."
        end
      else
        flash[:alert] = "Please fill out your shipping information before making an order."
      end
    else
      if create_charge
        ItemsPurchasedMailerWorker.perform_async(@cart.id, "rocco11nicholls@gmail.com")
        ItemsPurchasedMailerWorker.perform_async(@cart.id, @cart.email) unless Rails.env.development?
        ItemsPurchasedMailerWorker.perform_async(@cart.id, ENV["PKUT_EMAIL"]) unless Rails.env.development?
        session["cart_id"] = Cart.create.id
        flash[:notice] = "Cart was successfully purchased."
      else
        flash[:alert] = @stripe_error.presence || "There was an error with your request."
      end
    end

    items_with_redemption = @cart.items.select { |item| item.redemption_item_id }
    redemption_items = items_with_redemption.map(&:redemption_item)
    redemption_keys = redemption_items.each do |item|
      key = item.redemption_keys.create
      ApplicationMailer.delay.public_mailer(key.id, @cart.email)
    end

    if user_signed_in?
      redirect_to edit_user_registration_path
    else
      redirect_to root_path
    end
  end

  def item_params
    params[:line_item][:cost_in_pennies] = (params[:line_item][:cost_in_dollars].to_f * 100).round.to_s
    params.require(:line_item).permit(
      :description,
      :title,
      :display,
      :cost_in_pennies,
      :category,
      :hidden,
      :credits,
      :color,
      :size,
      :is_subscription,
      :taxable,
      :is_full_image,
      :redemption_item_id
    )
  end

  def set_categories
    @categories = ["Class", "Clothing", "Accessories", "Gift Card", "Other", "Coupon", "Redemption"]
  end

  def set_hidden
    @hidden_items = LineItem.where(hidden: true).reorder(created_at: :desc).map { |item| [item.title, item.id] }
  end

  def set_cart
    if user_signed_in?
      @cart = current_user.cart
    else
      if session["cart_id"].present?
        cart = Cart.find(session["cart_id"].to_i)
      else
        cart = Cart.create
        session["cart_id"] = cart.id
      end
      @cart = cart
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
