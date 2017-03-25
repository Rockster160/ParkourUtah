class UsersController < ApplicationController
  before_action :validate_user_signed_in, except: [ :new, :create ]
  before_action :verify_user_is_not_signed_in, only: [ :new, :create ]
  before_action :still_signed_in

  def new
    @user = User.new
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

  private

  def set_notifications
    @notifications = {
      account: [],
      athletes: [],
      notifications: [],
      subscriptions: [],
      contacts: []
    }
    @notifications[:notifications] << "You have blacklisted ParkourUtah!" unless @user.can_receive_sms?
    @user.athletes_where_expired_past_or_soon.each do |athlete|
      @notifications[:athletes] << "The waiver belonging to #{athlete.full_name} is about to expire!"
    end
    @user.athletes.unverified.each do |athlete|
      @notifications[:athletes] << "#{athlete.full_name} can receive 2 free trial classes by verifying their Fast Pass ID and Fast Pass Pin."
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
