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
    redirect_to step_2_path unless current_user.registration_complete?
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
    begin
      user = current_user
      stripe_id, subscriptions = current_user.recurring_subscriptions.where.not(stripe_id: nil).where(card_declined: true, auto_renew: true).group_by(&:stripe_id).first
      stripe_id ||= current_user.recurring_subscriptions.where.not(stripe_id: nil).last.try(:stripe_id)

      customer = ::Stripe::Customer.retrieve(stripe_id)
      customer.source = params["stripeToken"]
      customer.save

      total_cost = subscriptions.map(&:cost_in_pennies).sum
      stripe_charge = Stripe::Charge.create({
        amount:   total_cost,
        currency: "usd",
        customer: stripe_subscriptions.first.stripe_id
      })

      if stripe_charge.try(:status) == "succeeded"
        slack_message = "Charged Unlimited Subscriptions for #{user.email} at #{number_to_currency(total_cost/100.to_f)}."
        channel = Rails.env.production? ? "#purchases" : "#slack-testing"
        SlackNotifier.notify(slack_message, channel)

        subscriptions.each do |recurring_subscription|
          recurring_subscription.update(auto_renew: false, card_declined: false)
          new_sub = user.recurring_subscriptions.create(athlete_id: recurring_subscription.athlete_id, auto_renew: true, cost_in_pennies: recurring_subscription.cost_in_pennies, stripe_id: recurring_subscription.stripe_id)
          unless new_sub.persisted?
            SlackNotifier.notify("Failed to create new sub: ```#{new_sub.try(:attributes)}\n#{new_sub.try(:errors).try(:full_messages)}```", "#server-errors")
          end
        end
      else
        stripe_subscriptions.update_all(card_declined: true)
        SlackNotifier.notify("There was an issue updating the subscription for #{user.email}\n```#{stripe_charge}```", "#server-errors")
      end

      flash[:notice] = "Updated your card successfully!"
    rescue => e
      flash[:alert] = "There was an error updating your card. Please try again."
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
        @notifications[:athletes] << "#{athlete.full_name} can receive 2 free trial classes by verifying their Fast Pass ID and Fast Pass Pin."
      end
    end
    @user.recurring_subscriptions.unassigned.each do
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
