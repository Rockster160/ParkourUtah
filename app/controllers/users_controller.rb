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
    @user = current_user
    unless current_user.registration_complete?
      redirect_to step_2_path
    end
  end

  def update
    @user = current_user
    if current_user.update_with_password(user_params)
      bypass_sign_in @user
      redirect_to edit_user_path, notice: "Updated successfully!"
    else
      flash.now[:alert] = "Failed to update"
      render :edit
    end
  end

  private

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
