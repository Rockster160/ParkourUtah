class PeepsController < ApplicationController
  before_action :still_signed_in
  before_action :validate_instructor, except: [:return]

  def return
    current_user.get_payment_id
    current_user.get_shipping_id
    redirect_to edit_user_registration_path
  end

  def secret
  end

  def destroy_user
    if params[:confirmation] == "DELETE"
      User.find(params[:id]).destroy
      redirect_to recent_users_path, notice: "User successfully deleted."
    else
      redirect_to recent_users_path, notice: "Sorry, DELETE was not entered correctly. User still exists."
    end
  end

  def post_secret
    if params[:secret_code].to_i == 9
      Automator.activate!
    end
    redirect_to secret_path
  end

  def dashboard
    @classes = Event.all.select {|event| event.date.to_date == Time.now.to_date }
  end

  def pin_user
  end

  def edit
    @instructors = User.all.select { |u| u.is_instructor? }.sort_by { |s| s.instructor_position }
  end

  def recent_users
    @users = User.all.sort_by{|u|u.created_at}.reverse
  end

  def edit_peep
    @instructor = User.find(params[:id])
  end

  def update
    if User.find(params[:id]).update(instructor_params)
      flash[:notice] = "Instructor successfully updated."
    else
      flash[:alert] = "There was an error updating the instructor."
    end
    redirect_to dashboard_path
  end

  def update_peep_position
    @instructor = User.find(params[:id])
    @instructor.update(instructor_position: params["instructor"]["instructor_position"].to_i)
    respond_to do |format|
      format.json { render json: @instructor }
    end
  end

  def promote
    @instructor = User.new
  end

  def promotion
    new_user = false
    instructor = User.find_by_email(params[:user][:email])
    new_user = true if instructor.nil?
    instructor ||= User.new(email: params[:user][:email], password: "ParkourUtahPKFR4LF")
    instructor.update(instructor_params)
    if instructor.save
      number_of_instructors = User.all.select { |u| u.is_instructor? }.count
      instructor.update(role: 1, instructor_position: number_of_instructors + 1)
      # TODO Send Email
      flash[:notice] = "Instructor successfully created." if new_user == true
      flash[:notice] = "Instructor successfully added." if new_user == false
    else
      flash[:alert] = "There was an error adding the instructor."
    end
    redirect_to dashboard_path
  end

  def demotion
    if User.find(params[:id]).update(role: 0)
      flash[:notice] = "Instructor successfully removed."
    else
      flash[:alert] = "There was an error updating the instructor."
    end
    redirect_to dashboard_path
  end

  def show_user
    if params[:athlete_id].to_i == 0
      redirect_to dashboard_path
    elsif params[:athlete_id] == ENV["PKUT_PIN"]
      redirect_to class_logs_path(params[:id])
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
      charge_class(Event.find(params[:id]).cost_in_dollars, "Credits")
    elsif pin == ENV["PKUT_PIN"].to_i
      charge_class(0, "Cash")
    else
      redirect_to begin_class_path, alert: "Invalid Pin. Try again."
    end
  end

  def charge_class(charge, charge_type)
    @user = @athlete.user
    if @user.charge_credits(charge)
      Attendance.create(
        dependent_id: @athlete.athlete_id,
        user_id: current_user.id,
        event_id: params[:id],
        type_of_charge: charge_type
      )
      if @user.credits < 30
        if @user.notifications.email_low_credits && @user.has_unlimited_access? == false
          ::LowCreditsMailerWorker.perform_async(@user.id)
        end
        if @user.notifications.text_low_credits && @user.has_unlimited_access? == false
          ::SmsMailerWorker.perform_async(@user.phone_number, "You are low on Credits! Head up to ParkourUtah.com to get some more so you have some for next time.")
        end
      end
      flash[:notice] = "Success! Welcome to class."
      redirect_to begin_class_path
    else
      flash[:alert] = "Sorry, there are not enough credits in your account."
      redirect_to begin_class_path
    end
  end

  def class_logs
    @athletes = Attendance.where(event_id: params[:id]).select do |att|
      att.created_at.to_date == DateTime.now.to_date
    end.map { |a| a.athlete }
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

  def instructor_params
    params.require(:user).permit(:first_name, :last_name, :nickname, :stats, :payment_multiplier, :title, :bio, :avatar, :avatar_2, :role)
  end

  def still_signed_in
    current_user.still_signed_in! if current_user
  end
end
