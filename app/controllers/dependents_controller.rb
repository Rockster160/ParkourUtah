class DependentsController < ApplicationController
  layout 'application', except: [:secret]

  def new
    @dependent = Dependent.new
  end

  def create
    current_user.dependents.create(dependent_params)
    flash[:notice] = "Success! Now fill out a waiver to get an Athlete ID."
    redirect_to edit_user_registration_path
  end

  def waiver
  end

  def show
  end

  def secret
    # @user = User.first
  end

  def secret_submit
    id, pin = params[:pin].split('-')
    flash[:notice] = "User: #{id}, PIN: #{pin}"
    # if User.first.update(first_name: params[:user][:first_name])
    #   flash[:notice] = "Success! "
    # else
    #   flash[:alert] = "Failure..."
    # end
    redirect_to root_path
  end

  private

  def dependent_params
    params.require(:dependent).permit(:full_name, :emergency_contact, :athlete_pin, :user_id)
  end

end
