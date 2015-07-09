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

  def adjust_credits
    user = User[params[:url][:id]]
    user.credits += params[:adjust].to_i
    if user.save!
      redirect_to :back, notice: 'User successfully updated.'
    else
      redirect_to :back, alert: 'There was a problem updating the user.'
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
    @instructors = User.instructors
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
      RoccoLogger.add "Instructor successfully updated."
    else
      flash[:alert] = "There was an error updating the instructor."
      RoccoLogger.add "There was an error updating the instructor."
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
    new_pass = "UTPKFR4LF"
    new_user = false
    instructor = User.find_by_email(params[:user][:email])
    new_user = true if instructor.nil?
    instructor ||= User.new(email: params[:user][:email], password: new_pass)
    instructor.update(instructor_params)
    if instructor.save
      number_of_instructors = User.instructors.count
      instructor.update(role: 1, instructor_position: number_of_instructors + 1)
      flash[:notice] = "Instructor successfully created with password: #{new_pass}." if new_user == true
      flash[:notice] = "Instructor successfully promoted." if new_user == false
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
    User.update_instructor_positions
    redirect_to dashboard_path
  end

  def show_user
    if params[:athlete_id].to_i == 0
      redirect_to dashboard_path
    elsif params[:athlete_id] == ENV["PKUT_PIN"]
      redirect_to class_logs_path(params[:id])
      RoccoLogger.add "#{current_user.first_name} accessed the logs."
    else
      set_athlete
      if @athlete
        if Attendance.where(dependent_id: @athlete.athlete_id, event_id: params[:id]).count > 0
          redirect_to :back, alert: "Athlete already attending class."
          RoccoLogger.add "#{current_user.first_name} tried to add #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin}, but they are already in class."
        else
          if (Event.find(params[:id]).cost_in_dollars <= @athlete.user.credits) || @athlete.has_unlimited_access? || @athlete.has_trial?
            RoccoLogger.add "#{current_user.first_name} looked up #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin}."
          else
            RoccoLogger.add "#{current_user.first_name} tried to add #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin}, but insufficient funds."
            redirect_to :back, alert: "Sorry, there are not enough credits in your account."
          end
        end
      else
        redirect_to :back, alert: "Athlete not found."
        RoccoLogger.add "#{current_user.first_name} bad lookup - #{params[:athlete_id]}"
      end
    end
  end

  def pin_password
    unless params["commit"] == "√"
      flash[:alert] = "Pin rejected. Please try again."
      RoccoLogger.add "#{current_user.first_name} rejected #{Dependent.where(athlete_id: params[:athlete_id]).first.full_name}."
      redirect_to begin_class_path
    else
      if params[:athlete_photo]
        Dependent.where(athlete_id: params[:athlete_id]).first.update(athlete_photo: params[:athlete_photo])
        RoccoLogger.add "#{current_user.first_name} updated avatar for: #{Dependent.where(athlete_id: params[:athlete_id]).first.full_name}."
      end
      set_athlete
    end
  end

  def validate_pin
    set_athlete
    pin = params[:pin].to_i
    if pin == @athlete.athlete_pin
      charge_class(Event.find(params[:id]))
    # elsif pin == ENV["PKUT_PIN"].to_i
    #   charge_class(0, "Cash")
    else
      redirect_to begin_class_path, alert: "Invalid Pin. Re-enter Athlete ID."
    end
  end

  def charge_class(event)
    @user = @athlete.user
    charge = event.cost_in_dollars

    charge_type = if [1].include?(event.id) #83788378 - test class
      @user.charge_credits(charge)
    else
      @user.charge(charge, @athlete)
    end

    if charge_type
      Attendance.create(
        dependent_id: @athlete.athlete_id,
        user_id: current_user.id,
        event_id: params[:id],
        type_of_charge: charge_type
      )
      if @user.credits < 30
        if @user.notifications.email_low_credits && @athlete.has_unlimited_access? == false
          ::LowCreditsMailerWorker.perform_async(@user.id)
        end
        if @user.notifications.text_low_credits && @athlete.has_unlimited_access? == false
          ::SmsMailerWorker.perform_async(@user.phone_number, "You are low on Credits! Head up to ParkourUtah.com to get some more so you have some for next time.")
        end
      end
      RoccoLogger.add "#{current_user.first_name} successfully added #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin} to class."
      flash[:notice] = "Success! Welcome to class."
      redirect_to begin_class_path
    else
      RoccoLogger.add "#{current_user.first_name} tried to add #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin}, but insufficient funds."
      flash[:alert] = "Sorry, there are not enough credits in your account."
      redirect_to begin_class_path
    end
  end

  def class_logs
    @event = Event.find(params[:id])
    @athletes = Attendance.where(event_id: params[:id]).select do |att|
      att.created_at.to_date == DateTime.now.to_date
    end.map { |a| a.athlete }
  end

  private

  def set_athlete
    @athlete = Dependent.where("athlete_id = ?", params[:athlete_id]).first
  end

  def validate_instructor
    unless current_user && current_user.is_instructor?
      redirect_to new_user_session_path, alert: "You must be an Instructor to view this page."
    end
  end

  def instructor_params
    params.require(:user).permit(
      :email, :first_name, :last_name, :nickname,
      :stats, :payment_multiplier, :title, :bio,
      :avatar, :avatar_2, :role
    )
  end

  def still_signed_in
    current_user.still_signed_in! if current_user
  end
end
