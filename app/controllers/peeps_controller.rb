class PeepsController < ApplicationController
  include EmailHelper
  before_action :still_signed_in
  before_action :validate_instructor, except: [:return]

  EmailBody = Struct.new(:subject, :body, :recipients, :email_type)

  def user_page
    @user = User[params[:id]]
  end

  def email_body
    @email = EmailBody.new(*decoded_email_params)

    raw_html = html(@email.body)

    email_source = ContactMailer.email('', @email.subject || '', raw_html || '').body.raw_source

    respond_to do |format|
      if valid_html?(raw_html)
        format.json { render json: {email_body: email_source} }
      else
        format.json { render nothing: true, status: 422 }
      end
    end
  end

  def send_batch_texts
    phone_numbers = params[:recipients].gsub(/[^\d|,]/, '').split(",").map(&:squish)
    @success = []
    @failed = []
    phone_numbers.each do |phone_number|
      if phone_number.length == 10
        SmsMailerWorker.perform_async(phone_number, params[:message])
        @success << phone_number
      else
        @failed << phone_number
      end
    end
    render :admin_texter
  end

  def batch_emailer
    @email = EmailBody.new(*decoded_email_params)
  end

  def send_batch_emailer
    @email = EmailBody.new(*decoded_email_params)
    raw_html = html(@email.body)
    BatchEmailerWorker.perform_async(@email.subject, raw_html, @email.recipients, @email.email_type)
    redirect_to dashboard_path, notice: 'Sweet! I will send that out to them!'
  end

  def cheat_login
    user = User.find_by_encrypted_password(Base64.urlsafe_decode64(params[:ecp]))
    sign_out :user
    sign_in user
    redirect_to edit_user_registration_path
  end

  def bought_classes
    @line_item_ids = params[:line_item_ids].present? ? params[:line_item_ids].compact.map(&:to_i) : [2, 26, 27, 29, 30, 24]
    line_items = LineItem.where(id: @line_item_ids)
    @items_with_users = line_items.map do |line_item|
      {
        line_item_id: line_item.id,
        users: line_item.users_who_purchased
      }
    end
  end

  def attendance_page
    @athletes = User[params[:id]].athletes
  end

  def edit_trial
    athlete = Dependent.find(params[:id])
    if params[:num].to_i < 0
      params[:num].to_i.abs.times do
        athlete.trial.use!
      end
    else
      params[:num].to_i.abs.times do
        athlete.trial_classes.create
      end
    end
    redirect_to :back
  end

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

  def edit_user_notifications
    user = User.find(params[:id])
    user.notifications.blow!
    params[:notify].each do |attribute, value|
      user.notifications.update(attribute => true)
    end
    redirect_to :back
  end

  def adjust_credits
    user = User[params[:id]]
    user.credits += params[:adjust].to_i
    if user.save!
      redirect_to :back, notice: 'User successfully updated.'
    else
      redirect_to :back, alert: 'There was a problem updating the user.'
    end
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
    @all_users_count = User.count
    @users = User.order(created_at: :desc)
    @users = @users.by_fuzzy_text(params[:by_fuzzy_text]) if params[:by_fuzzy_text]
    @users = @users.page(params[:page] || 1)

    respond_to do |format|
      format.json { render json: @users.to_json(include: :dependents) }
      format.html
    end
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
            redirect_to pin_password_path(athlete_id: params[:athlete_id])
          else
            RoccoLogger.add "#{current_user.first_name} tried to add #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin}, but insufficient funds."
            redirect_to :back, alert: "Sorry, #{@athlete.full_name} does not have enough credits in their account."
          end
        end
      else
        redirect_to :back, alert: "Athlete not found."
        RoccoLogger.add "#{current_user.first_name} bad lookup - #{params[:athlete_id]}"
      end
    end
  end

  def pin_password
    if params[:athlete_photo]
      Dependent.where(athlete_id: params[:athlete_id]).first.update(athlete_photo: params[:athlete_photo])
      RoccoLogger.add "#{current_user.first_name} updated avatar for: #{Dependent.where(athlete_id: params[:athlete_id]).first.full_name}."
    end
    set_athlete
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
      if @user.credits < 30 && @athlete.has_unlimited_access? == false
        if @user.notifications.email_low_credits
          ::LowCreditsMailerWorker.perform_async(@user.id)
        end
        if @user.notifications.text_low_credits && @user.notifications.sms_receivable
          ::SmsMailerWorker.perform_async(@user.phone_number, "You are low on Credits! Head up to ParkourUtah.com/store to get some more so you have some for next time.")
        end
      end
      RoccoLogger.add "#{current_user.first_name} successfully added #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin} to class."
      flash[:notice] = "Success! Welcome to class."
      redirect_to begin_class_path
    else
      RoccoLogger.add "#{current_user.first_name} tried to add #{@athlete.athlete_id}:#{@athlete.full_name}-#{@athlete.athlete_pin}, but insufficient funds."
      flash[:alert] = "Sorry, #{@athlete.full_name} does not have enough credits in their account."
      redirect_to begin_class_path
    end
  end

  def class_logs
    @event = Event.find(params[:id])
    @athletes = Attendance.where(event_id: params[:id]).map { |a| a.athlete }
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

  def decoded_email_params
    if params[:encoded] == 'true'
      [Base64.urlsafe_decode64(params[:subject] || ''), Base64.urlsafe_decode64(params[:body] || ''), Base64.urlsafe_decode64(params[:recipients] || ''), Base64.urlsafe_decode64(params[:email_type] || '')]
    else
      [params[:subject], params[:body], params[:recipients], params[:email_type]]
    end
  end

end
