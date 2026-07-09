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

    begin
      # Reuse any existing Stripe customer on file for this user (from prior
      # RS or PPI); otherwise create a new one.
      existing_stripe_id = user.recurring_subscriptions.where.not(stripe_id: [nil, ""]).order(created_at: :desc).limit(1).pluck(:stripe_id).first
      existing_stripe_id ||= user.purchased_plan_items.where.not(stripe_id: [nil, ""]).order(created_at: :desc).limit(1).pluck(:stripe_id).first

      customer = if existing_stripe_id.present?
        c = ::Stripe::Customer.retrieve(existing_stripe_id)
        c.source = params["stripeToken"]
        c.save
        c
      else
        ::Stripe::Customer.create(source: params["stripeToken"], description: user.email)
      end

      # Point every current, auto-renewing sub/plan at this customer so the
      # monthly worker actually finds it. Also clears any prior card-declined
      # flag so declines get another shot.
      user.recurring_subscriptions.where(auto_renew: true).update_all(stripe_id: customer.id, card_declined: false)
      user.purchased_plan_items.where(auto_renew: true).update_all(stripe_id: customer.id, card_declined: nil)

      # If any of those subs are already past due, retry the missed charge now
      # so the customer doesn't wait for the next scheduled run.
      overdue_ppis = user.purchased_plan_items.assigned.auto_renew.inactive.available.to_a
      overdue_rs = user.recurring_subscriptions.assigned.auto_renew.expired.available.to_a

      overdue_ppis.group_by(&:stripe_id).each do |stripe_id, plans|
        next if stripe_id.blank?
        total_cost = plans.map(&:cost_in_pennies).sum
        stripe_charge = ::Stripe::Charge.create(amount: total_cost, currency: "usd", customer: stripe_id)
        next unless stripe_charge.try(:status) == "succeeded"
        SlackNotifier.notify("Charged Plan Subscriptions for #{user.email} at #{helpers.number_to_currency(total_cost/100.to_f)} (via billing update).", Rails.env.production? ? "#purchases" : "#slack-testing")
        plans.each do |plan|
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

      overdue_rs.group_by(&:stripe_id).each do |stripe_id, subs|
        next if stripe_id.blank?
        total_cost = subs.map(&:cost_in_pennies).sum
        stripe_charge = ::Stripe::Charge.create(amount: total_cost, currency: "usd", customer: stripe_id)
        next unless stripe_charge.try(:status) == "succeeded"
        SlackNotifier.notify("Charged Unlimited Subscriptions for #{user.email} at #{helpers.number_to_currency(total_cost/100.to_f)} (via billing update).", Rails.env.production? ? "#purchases" : "#slack-testing")
        subs.each do |sub|
          sub.update(auto_renew: false)
          user.recurring_subscriptions.create(athlete_id: sub.athlete_id, auto_renew: true, cost_in_pennies: sub.cost_in_pennies, stripe_id: sub.stripe_id)
        end
      end

      flash[:notice] = "Updated your card successfully!"
    rescue StandardError => e
      SlackNotifier.notify("update_card_details failed for #{user.email}: ```#{e.class}: #{e.message}```", "#server-errors") rescue nil
      flash[:alert] = "There was an error updating your card. Please try again or contact support."
    end

    redirect_to account_path(anchor: "subscriptions")
  end

  private

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
