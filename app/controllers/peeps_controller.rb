class PeepsController < ApplicationController
  layout 'application', except: [:secret]

  def show
    @instructor = User.find(params[:id])
    redirect_to root_path unless @instructor.is_instructor?
  end

  def return
    current_user.get_payment_id
    redirect_to edit_user_registration_path
  end

  def dashboard
    unless current_user && current_user.is_instructor?
      flash[:alert] = "You are not authorized to view this page."
      redirect_to root_path
    end
    @classes = Event.all.select { |event| event.date.today? }
  end

  def pin_user
  end

  def show_user
    create_athlete
    unless @athlete
      flash[:alert] = "User not found."
      redirect_to :back
    end
  end

  def pin_password
    create_athlete
    unless params["commit"] == "√"
      redirect_to begin_class_path
    end
  end

  def charge_class
    create_athlete
    if params[:pin].to_i == @athlete.athlete_pin
      @user = User.find(@athlete.user_id)
      @user.charge_class
      flash[:notice] = "Success!"
      redirect_to begin_class_path
    else
      flash[:alert] = "Invalid Pin. Try again."
      redirect_to :back
    end
  end

  def secret_submit
    id, pin = params[:pin].split('-')
    # flash[:notice] = "User: #{id}, PIN: #{pin}"
    # if User.first.update(first_name: params[:user][:first_name])
    #   flash[:notice] = "Success! "
    # else
    #   flash[:alert] = "Failure..."
    # end
    redirect_to root_path
  end

  private

  def create_athlete
    @athlete = Dependent.where("athlete_id = ?", params[:athlete_id]).first
  end
end
