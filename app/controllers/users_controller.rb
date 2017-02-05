class UsersController < ApplicationController
  before_action :validate_user_signed_in, except: [ :new, :create ]
  before_action :still_signed_in

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if (verify_recaptcha || !(Rails.env.production?)) && @user.save
      sign_in :user, @user
      redirect_to step_2_path
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

  def address_params
    params.require(:address).permit(:line1, :line2, :city, :state, :zip)
  end

  def ec_contact_params
    params.require(:emergency_contacts).permit(:name, :number)
  end

end
