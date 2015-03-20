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
    @classes = Event.all.select {|event| event.date.to_date == Time.now.to_date }
  end

  def pin_user
  end

  def show_user
    if params[:athlete_id] == "0000"
      redirect_to dashboard_path
    else
      create_athlete
      if @athlete
        if Attendance.where(dependent_id: @athlete.athlete_id, event_id: params[:id]).count > 0
          redirect_to :back
           "Athlete already attending class."
        end
      else
        redirect_to :back
         "Athlete not found."
      end
    end
  end

  def pin_password
    unless params["commit"] == "√"
      flash[:alert] = "Pin rejected. Please try again."
      redirect_to begin_class_path
    else
      create_athlete
    end
  end

  def validate_pin
    create_athlete
    pin = params[:pin].to_i
    if pin == @athlete.athlete_pin
      charge_class(15, "Credits")
    elsif pin == 7545
      charge_class(0, "Cash")
    else
      flash[:alert] = "Invalid Pin. Try again."
      redirect_to :back
    end
  end

  def charge_class(charge, charge_type)
    @user = User.find(@athlete.user_id)
    if @user.charge_credits(charge)
      Attendance.create(
        dependent_id: @athlete.athlete_id,
        instructor_id: current_user.id,
        event_id: params[:id],
        type_of_charge: charge_type
      )
      flash[:notice] = "Success!"
      redirect_to begin_class_path
    else
      flash[:alert] = "Sorry, there are not enough credits in your account."
      redirect_to begin_class_path
    end
  end

  private

  def create_athlete
    @athlete = Dependent.where("athlete_id = ?", params[:athlete_id]).first
  end
end
