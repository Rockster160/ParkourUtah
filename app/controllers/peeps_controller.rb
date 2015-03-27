class PeepsController < ApplicationController
  before_action :validate_instructor

  def return
    current_user.get_payment_id
    redirect_to edit_user_registration_path
  end

  def dashboard
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
          redirect_to :back, alert: "Athlete already attending class."
        end
      else
        redirect_to :back, alert: "Athlete not found."
      end
    end
  end

  def pin_password
    unless params["commit"] == "√"
      flash[:alert] = "Pin rejected. Please try again."
      redirect_to begin_class_path
    else
      if params[:athlete_photo]
        Dependent.where(athlete_id: params[:athlete_id]).first.update(athlete_photo: params[:athlete_photo])
      end
      create_athlete
    end
  end

  def validate_pin
    create_athlete
    pin = params[:pin].to_i
    if pin == @athlete.athlete_pin
      charge_class(ENV["PKUT_PRICE"].to_i, "Credits")
    elsif pin == ENV["PKUT_PIN"].to_i
      charge_class(0, "Cash")
    else
      redirect_to begin_class_path, alert: "Invalid Pin. Try again."
    end
  end

  def charge_class(charge, charge_type)
    @user = User.find(@athlete.user_id)
    if @user.charge_credits(charge)
      Attendance.create(
        dependent_id: @athlete.athlete_id,
        user_id: current_user.id,
        event_id: params[:id],
        type_of_charge: charge_type
      )
      flash[:notice] = "Success! Welcome to class."
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

  def validate_instructor
    unless current_user && current_user.is_instructor?
      redirect_to new_user_session_path, alert: "You must be an Instructor to view this page."
    end
  end
end
