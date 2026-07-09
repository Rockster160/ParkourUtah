class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :validate_user_signed_in, except: [ :freeplay, :new, :create ]
  before_action :verify_user_is_not_signed_in, only: [ :freeplay, :new, :create ]
  before_action :still_signed_in

  def new
    @user = User.new
  end

  def freeplay
    @user = User.new(skip_trials: true)

    render :new
  end

  def create
    @user = User.new(user_params)
    if (verify_recaptcha || !(Rails.env.production?))
      if @user.save
        sign_in :user, @user
        redirect_to step_2_path
      else
        flash.now[:alert] = "Could not save your account. Please try again."
        render :new
      end
    else
      flash.now[:alert] = "You failed the bot test. Make sure to wait for the green checkmark to appear."
      render :new
    end
  end

  def edit
    return redirect_to(registration_step_path_for(current_user)) unless current_user.registration_complete?
    @user = current_user
    set_notifications
  end

  def update
    @user = current_user
    successful_update = false

    if params[:user].keys == ["emergency_contacts_attributes"]
      successful_update = current_user.update(user_params)
    else
      successful_update = current_user.update_with_password(user_params)
    end

    if successful_update
      bypass_sign_in @user
      redirect_to account_path, notice: "Updated successfully!"
    else
      flash.now[:alert] = "Failed to update"
      set_notifications
      render :edit
    end
  end

  def update_card_details
    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
    user = current_user

    # Step 1: save the card. This must succeed for the flow to make sense —
    # any failure here means we could not even update Stripe, so bail early.
    customer = save_stripe_customer_for(user, params["stripeToken"])
    unless customer
      flash[:alert] = "There was an error updating your card. Please try again or contact support."
      redirect_to(account_path(anchor: "subscriptions")) and return
    end

    # Step 2: point every current auto-renewing sub/plan at this customer so
    # the monthly worker actually finds it, and clear any prior card-declined
    # flag so declines get another shot.
    user.recurring_subscriptions.where(auto_renew: true).update_all(stripe_id: customer.id, card_declined: false)
    user.purchased_plan_items.where(auto_renew: true).update_all(stripe_id: customer.id, card_declined: nil)

    # Step 3 (best-effort): retry any already-past-due charges now so the
    # customer doesn't wait for the next scheduled run. Per-group rescue so
    # one failing charge doesn't roll the others back or mask that Step 1/2
    # succeeded.
    missed_results = collect_missed_charges_for(user)

    flash[:notice] = missed_results.success_message
    flash[:alert] = missed_results.failure_message if missed_results.failure_message

    redirect_to account_path(anchor: "subscriptions")
  end

  private

  MissedChargeResults = Struct.new(:successes, :failures) do
    def success_message
      base = "Card updated successfully."
      return base if successes.empty?
      collected = successes.map { |c| ActionController::Base.helpers.number_to_currency(c/100.0) }.join(", ")
      "#{base} Missed charge collected: #{collected}."
    end

    def failure_message
      return nil if failures.empty?
      "Your card is saved, but we couldn't collect a past-due charge. We'll retry on the next scheduled run — no action needed from you."
    end
  end

  def save_stripe_customer_for(user, token)
    existing_stripe_id = user.recurring_subscriptions.where.not(stripe_id: [nil, ""]).order(created_at: :desc).limit(1).pluck(:stripe_id).first
    existing_stripe_id ||= user.purchased_plan_items.where.not(stripe_id: [nil, ""]).order(created_at: :desc).limit(1).pluck(:stripe_id).first

    if existing_stripe_id.present?
      c = ::Stripe::Customer.retrieve(existing_stripe_id)
      c.source = token
      c.save
      c
    else
      ::Stripe::Customer.create(source: token, description: user.email)
    end
  rescue StandardError => e
    SlackNotifier.notify("update_card_details customer save failed for #{user.email}: ```#{e.class}: #{e.message}```", "#server-errors") rescue nil
    nil
  end

  # Charge each group of past-due subs individually. Card declines and other
  # Stripe errors are captured per-group so one failure doesn't torpedo the
  # rest. On decline, mark card_declined so the record drops out of the
  # `.available` scope until the customer updates their card again.
  def collect_missed_charges_for(user)
    results = MissedChargeResults.new([], [])

    overdue_ppis = user.purchased_plan_items.assigned.auto_renew.inactive.available.to_a
    overdue_rs = user.recurring_subscriptions.assigned.auto_renew.expired.available.to_a

    overdue_ppis.group_by(&:stripe_id).each do |stripe_id, plans|
      next if stripe_id.blank?
      charge_missed_plan_group(user, stripe_id, plans, results)
    end

    overdue_rs.group_by(&:stripe_id).each do |stripe_id, subs|
      next if stripe_id.blank?
      charge_missed_rs_group(user, stripe_id, subs, results)
    end

    results
  end

  def charge_missed_plan_group(user, stripe_id, plans, results)
    total_cost = plans.map(&:cost_in_pennies).sum
    return if total_cost <= 0

    ::Stripe::Charge.create(amount: total_cost, currency: "usd", customer: stripe_id)

    SlackNotifier.notify(
      "Charged Plan Subscriptions for #{user.email} at #{ActionController::Base.helpers.number_to_currency(total_cost/100.0)} (via billing update).",
      Rails.env.production? ? "#purchases" : "#slack-testing"
    )
    results.successes << total_cost

    plans.each do |plan|
      PurchasedPlanItem.transaction do
        plan.lock!
        plan.update(auto_renew: false)
        user.purchased_plan_items.create(
          athlete_id: plan.athlete_id,
          stripe_id: plan.stripe_id,
          plan_item_id: plan.plan_item_id,
          cost_in_pennies: plan.cost_in_pennies,
          discount_items: plan.discount_items,
          free_items: plan.free_items,
          expires_at: 1.month.from_now,
        )
      end
    end
  rescue ::Stripe::CardError => e
    plans.each { |p| p.update(card_declined: e.message) }
    SlackNotifier.notify("Missed-charge collection declined for #{user.email}: #{e.message}", "#server-errors") rescue nil
    results.failures << total_cost
  rescue StandardError => e
    SlackNotifier.notify("Missed-charge collection error for #{user.email}: ```#{e.class}: #{e.message}```", "#server-errors") rescue nil
    results.failures << total_cost
  end

  def charge_missed_rs_group(user, stripe_id, subs, results)
    total_cost = subs.map(&:cost_in_pennies).sum
    return if total_cost <= 0

    ::Stripe::Charge.create(amount: total_cost, currency: "usd", customer: stripe_id)

    SlackNotifier.notify(
      "Charged Unlimited Subscriptions for #{user.email} at #{ActionController::Base.helpers.number_to_currency(total_cost/100.0)} (via billing update).",
      Rails.env.production? ? "#purchases" : "#slack-testing"
    )
    results.successes << total_cost

    subs.each do |sub|
      RecurringSubscription.transaction do
        sub.lock!
        sub.update(auto_renew: false)
        user.recurring_subscriptions.create(athlete_id: sub.athlete_id, auto_renew: true, cost_in_pennies: sub.cost_in_pennies, stripe_id: sub.stripe_id)
      end
    end
  rescue ::Stripe::CardError => e
    subs.each { |s| s.update(card_declined: true) }
    SlackNotifier.notify("Missed-charge collection declined for #{user.email}: #{e.message}", "#server-errors") rescue nil
    results.failures << total_cost
  rescue StandardError => e
    SlackNotifier.notify("Missed-charge collection error for #{user.email}: ```#{e.class}: #{e.message}```", "#server-errors") rescue nil
    results.failures << total_cost
  end

  def set_notifications
    @notifications = {
      account: [],
      athletes: [],
      notifications: [],
      subscriptions: [],
      contacts: []
    }
    @notifications[:account] << "Your card was declined while we tried to charge your unlimited credits subscription. Visit the Subscriptions tab to update your card information." if @user.card_declined?
    @notifications[:subscriptions] << "Your card was declined while we tried to charge your unlimited credits subscription. Click the \"Update Card Information\" link below to update." if @user.card_declined?
    @notifications[:notifications] << "You have blacklisted ParkourUtah!" unless @user.can_receive_sms?
    @user.athletes_where_expired_past_or_soon.each do |athlete|
      @notifications[:athletes] << "The waiver belonging to #{athlete.full_name} is about to expire!"
    end
    unless @user.skip_trials?
      @user.athletes.unverified.each do |athlete|
        @notifications[:athletes] << "#{athlete.full_name} can receive 1 free trial class by verifying their Fast Pass ID and Fast Pass Pin."
      end
    end
    @user.recurring_subscriptions.unassigned.each do
      @notifications[:subscriptions] << "You have unassigned subscriptions!"
    end
    @user.purchased_plan_items.unassigned.each do
      @notifications[:subscriptions] << "You have unassigned subscriptions!"
    end
  end

  def user_params
    params.require(:user).permit(
      :email,
      :phone_number,
      :password,
      :password_confirmation,
      :current_password,
      :skip_trials,
      emergency_contacts_attributes: [
        :id,
        :number,
        :name
      ],
      address_attributes: [
        :id,
        :line1,
        :line2,
        :city,
        :state,
        :zip
      ]
    )
  end

end
