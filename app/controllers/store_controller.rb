class StoreController < ApplicationController
  before_action :set_cart
  skip_before_action :verify_authenticity_token

  def index
    @items_by_category = {}
    LineItem.where.not(hidden: true).order(item_order: :asc).each do |item|
      dest = case item.category
      when "Class" then :classes
      when "Clothing" then :clothing
      when "Accessories" then :accessories
      when "Gift Card" then :gift_card
      else :other
      end
      @items_by_category[dest] ||= []
      @items_by_category[dest] << item
    end
  end

  def generate_keys
    @hidden = LineItem.where(hidden: true).reorder(created_at: :desc)
  end

  def unsubscribe
    athlete = Athlete.find(params[:id])
    if athlete.current_subscription.update(auto_renew: false)
      redirect_to account_path(anchor: :subscriptions), notice: 'Successfully Unsubscribed'
    else
      redirect_to account_path(anchor: :subscriptions), notice: 'There was an error unsubscribing.'
    end
  end

  def update_cart
    if params[:delete_all]
      @cart.cart_items.destroy_all
    else
      item = LineItem.find_by(id: params[:item_id]) if params[:item_id]
      item_title = item&.title || params[:item_name]
      size = params[:size] ? "#{params[:size]} " : ""
      color = params[:color] ? "#{params[:color]} " : ""
      instructor = params[:instructor_name] ? "#{params[:instructor_name]} " : ""
      location = params[:location_name] ? " at #{params[:location_name]}" : ""
      time = params[:desired_time] ? ", #{params[:desired_time]}" : ""
      name = "#{size}#{color}#{instructor}#{item_title}#{location}#{time}"

      discount_data = item&.discounted_cost_data(current_user) || {}

      orders = @cart.cart_items
      order = orders.find_by(order_name: name)

      if params[:new_amount]
        params[:new_amount] ||= "0"
        if params[:new_amount].to_i <= 0
          order&.destroy!
        else
          order&.update(amount: params[:new_amount])
        end
      else
        if order
          order.increment!(:amount)
        else
          order = CartItem.create(
            line_item_id: item.id,
            order_name: name,
            discount_cost_in_pennies: discount_data[:cost],
            discount_type: discount_data[:discount],
            purchased_plan_item_id: discount_data[:plan_id],
          )
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
    if key.present? && !key.redeemed? && !key.expired?
      items_with_key = @cart.cart_items.where(redeemed_token: params[:redemption_key])
      if key.item.present? && (items_with_key.none? || key.can_be_used_multiple_times?)
        @order = CartItem.create(line_item_id: key.line_item_id, redeemed_token: params[:redemption_key], cart_id: @cart.try(:id))
      end
    end
    @redeemed_token = true
    @invalid = !@order

    render :update_cart
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
        @cart_is_subscription = @cart.items.any?(&:is_subscription)
        create_customer if @cart_is_subscription
        purchase_cart
      else
        categories = @cart.items.map(&:category).uniq
        if categories.count == 1 && categories.first == "Gift Card"
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
    @customer = Stripe::Customer.create(
      source: token,
      description: params[:stripeEmail]
    )
  end

  def create_charge
    stripe_charge = nil
    if @cart.price > 0
      begin
        stripe_charge = Stripe::Charge.create({
          amount: @cart.total,
          currency: "usd"
        }.merge(@customer.present? ? {customer: @customer.id} : {source: params[:stripeToken]}))
      rescue Stripe::CardError => e
        stripe_charge = {failure_message: "Failed to Charge: #{e}"}
      rescue StandardError => e
        CustomLogger.log("\e[31mOther error: \n#{e}\e[0m")
        stripe_charge = {failure_message: "Failed to Charge, try logging out and back in or trying a different browser."}
      end
    end
    # Probably shouldn't be a nil check here- nil should be an invalid charge
    order_success = stripe_charge.nil? || stripe_charge.try(:status) == "succeeded"
    if order_success
      @cart.update(purchased_at: DateTime.current)
      @cart.cart_items.each do |order|
        line_item = LineItem.find(order.line_item_id)
        if RedemptionKey.redeem(order.redeemed_token)
          current_user.update(credits: (current_user.credits + (order.amount * line_item.credits))) if user_signed_in?
        end
        if line_item.id == 44
          order.amount.times do
            new_sub = current_user.recurring_subscriptions.create(cost_in_pennies: 55, auto_renew: false)
            unless new_sub.persisted?
              CustomLogger.log("Discount Subscription Error! User: #{current_user.try(:id)} Item: #{line_item.try(:id)} Cost: #{line_item.try(:cost_in_pennies)}")
            end
          end
        end
        plan_item = line_item.plan_item
        if plan_item.present?
          @purchased_subscription = true
          current_user.purchased_plan_items.create(
            cart_id: @cart.id,
            stripe_id: @customer.try(:id),
            plan_item_id: plan_item.id,
            cost_in_pennies: line_item.cost_in_pennies,
            discount_items: plan_item.discount_items,
            free_items: plan_item.free_items,
          )
        end
        if line_item.is_subscription? && user_signed_in?
          @purchased_subscription = true
          order.amount.times do
            new_sub = current_user.recurring_subscriptions.create(cost_in_pennies: line_item.cost_in_pennies, stripe_id: @customer.try(:id))
            unless new_sub.persisted?
              CustomLogger.log("Subscription Error! User: #{current_user.try(:id)} Item: #{line_item.try(:id)} Cost: #{line_item.try(:cost_in_pennies)} CustID: #{@customer.try(:id)}")
            end
          end
        end
      end
    else
      @stripe_error = stripe_charge.try(:failure_message)
      CustomLogger.log("Stripe Error: \e[31m#{stripe_charge}\e[0m", current_user, nil)
    end
    @did_charge = order_success
    return order_success
  end

  def purchase_cart
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']

    if user_signed_in?
      if current_user.address && current_user.address.valid?
        if create_charge
          ApplicationMailer.customer_purchase_mail(current_user.cart.id, @cart.email).deliver_later unless Rails.env.development?
          @cart.notify_slack_of_purchase
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
        ApplicationMailer.customer_purchase_mail(@cart.id, @cart.email).deliver_later unless Rails.env.development?
        session["cart_id"] = Cart.create.id
        flash[:notice] = "Cart was successfully purchased."
      else
        flash[:alert] = @stripe_error.presence || "There was an error with your request."
      end
    end

    if @did_charge
      items_with_redemption = @cart.items.select { |item| item.redemption_item_id }
      redemption_items = items_with_redemption.map(&:redemption_item)
      redemption_keys = redemption_items.each do |item|
        key = item.redemption_keys.create
        ApplicationMailer.delay.public_mailer(key.id, @cart.email)
      end
    end

    if user_signed_in?
      redirect_to account_path(anchor: @purchased_subscription ? :subscriptions : nil, trigger_fb_purchase: {value: @cart.total_in_dollars, item_ids: @cart.items.map(&:id), currency: 'USD'})
    else
      redirect_to root_path(trigger_fb_purchase: {value: @cart.total_in_dollars, item_ids: @cart.items.map(&:id), currency: 'USD'})
    end
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

end
