class PeepsController < ApplicationController
  include EmailHelper
  before_action :still_signed_in, :validate_instructor

  EmailBody = Struct.new(:subject, :body, :recipients, :email_type)

  def user_page
    @user = User[params[:id]]
  end

  def email_body
    @email = EmailBody.new(*decoded_email_params)

    raw_html = html(@email.body)

    email_source = ApplicationMailer.email('', @email.subject || '', raw_html || '').body.raw_source

    respond_to do |format|
      if valid_html?(raw_html)
        format.json { render json: {email_body: email_source} }
      else
        format.json { render nothing: true, status: 422 }
      end
    end
  end

  def admin_texter
    @users = User.where(id: params[:user_ids])
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
    @line_item_ids = (params[:line_item_ids].try(:compact) || []).map(&:to_i)
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
    if user.save
      redirect_to :back, notice: 'User successfully updated.'
    else
      redirect_to :back, alert: 'There was a problem updating the user.'
    end
  end

  def dashboard
    @classes = EventSchedule.events_today
  end

  def pin_user
  end

  def edit
    @instructors = User.instructors
  end

  def recent_users
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

  private

  def instructor_params
    params.require(:user).permit(
      :email, :first_name, :last_name, :nickname,
      :stats, :payment_multiplier, :title, :bio,
      :avatar, :avatar_2, :role
    )
  end

  def decoded_email_params
    if params[:encoded] == 'true'
      [Base64.urlsafe_decode64(params[:subject] || ''), Base64.urlsafe_decode64(params[:body] || ''), Base64.urlsafe_decode64(params[:recipients] || ''), Base64.urlsafe_decode64(params[:email_type] || '')]
    else
      [params[:subject], params[:body], params[:recipients], params[:email_type]]
    end
  end

end
