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
    create_athlete
    if @athlete
      if Attendance.where(dependent_id: @athlete.athlete_id, event_id: params[:id]).count > 0
        redirect_to :back, alert: "Athlete already attending class."
      end
    else
      redirect_to :back, alert: "Athlete not found."
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
      redirect_to :back, alert: "Invalid Pin. Try again."
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
      redirect_to begin_class_path, notice: "Success!"
    else
      redirect_to begin_class_path, alert: "Sorry, there are not enough credits in your account."
    end
  end

  private

  def create_athlete
    @athlete = Dependent.where("athlete_id = ?", params[:athlete_id]).first
  end
end
