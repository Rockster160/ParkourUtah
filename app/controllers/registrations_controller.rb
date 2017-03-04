class RegistrationsController < ApplicationController
  before_action :verify_user_signed_in
  before_action :redirect_user_to_correct_step

  def step_4
    @athletes = @user.athletes.select {|athlete| athlete.signed_waiver? == false }
  end

  def step_5
    if @user.registration_step == 5
      @user.update(registration_complete: true)
    end
  end

  def step_2
    @user = @user
  end

  def post_step_2
    if @user.update(user_params.merge(registration_step: 3))
      redirect_to step_3_path, notice: "Success!"
    else
      flash.now[:alert] = "Looks like we're missing some information."
      render :step_2
    end
  end

  def post_step_3
    valid = []
    params[:athlete].each do |token, athlete|
      if validate_athlete_attributes(athlete)
        new_athlete = @user.athletes.create(
          full_name: athlete[:name],
          date_of_birth: athlete[:dob],
          fast_pass_pin: athlete[:code]
        )
        new_athlete.waivers.create(
          signed_for: new_athlete.full_name,
          signed_by: params[:signed_by],
        )
        valid << new_athlete
      end
    end
    if valid.count >= 1
      @user.update(registration_step: 4)
      redirect_to step_4_path, notice: "Success! #{valid.count} #{'waiver'.pluralize(valid.count)} created."
    else
      redirect_back fallback_location: root_path, alert: "An error occurred."
    end
  end

  def validate_athlete_attributes(athlete)
    all_good = true
    all_good = false unless athlete[:name].length > 0
    all_good = false unless athlete[:dob].length == 10
    all_good = false unless athlete[:code].length == 4
    all_good
  end

  def fix_step_4
    if @user.update(address_params)
      redirect_to step_4_path, notice: "We've updated the requested changes."
    else
      redirect_back fallback_location: root_path, alert: "Something went wrong."
    end
  end

  def update_athletes
    valid = true
    params[:athlete].each do |fast_pass_id, values|
      athlete = Athlete.find(fast_pass_id)
      temp_valid = athlete.update(
        full_name: values[:name],
        date_of_birth: values[:dob],
        fast_pass_pin: values[:code]
      )
      athlete.waiver.update(
        signed_for: values[:name]
      )
      valid = temp_valid if valid == true
    end
    valid
  end

  def post_step_4
    approved = []
    params[:agreed].each do |id, vals|
      athlete = Athlete.find(id)
      if athlete.sign_waiver!
        approved << athlete.id
        athlete.generate_pin
      end
    end

    slack_message = "New User: <#{admin_user_url(@user)}|#{@user.id} #{@user.email}>\n"
    @user.athletes.each do |athlete|
      slack_message << "#{athlete.id} #{athlete.full_name} - Athlete ID: #{athlete.fast_pass_id.to_s.rjust(4, "0")} Pin: #{athlete.fast_pass_pin.to_s.rjust(4, "0")}\n"
    end
    slack_message << "Referred By: #{@user.referrer}"
    channel = Rails.env.production? ? "#new-users" : "#slack-testing"
    SlackNotifier.notify(slack_message, channel)

    ::NewAthleteInfoMailerWorker.perform_async(approved.compact)
    @user.update(registration_step: 5)
    redirect_to step_5_path
  end

  private

  def user_params
    params[:user][:referrer] = params[:user][:referrer] == "Word of Mouth" ? params[:user][:referrer_text] : params[:user][:referrer]
    params.require(:user).permit([
      :phone_number,
      :email,
      :referrer,
      :sms_alert,
      notifications_attributes: [
        :id,
        :email_class_reminder,
        :text_class_reminder,
        :email_low_credits,
        :text_low_credits,
        :email_waiver_expiring,
        :text_waiver_expiring,
        :sms_receivable,
        :text_class_cancelled,
        :email_class_cancelled,
        :email_newsletter
      ],
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
    ])
  end

  def verify_user_signed_in
    @user = current_user
    if user_signed_in?
      if @user.registration_complete?
        redirect_to edit_user_path
      end
    else
      redirect_to root_path, alert: "Must be signed in to do that."
    end
  end

  def current_step
    params[:action].gsub(/[^0-9]/, '').to_i
  end

  def redirect_user_to_correct_step
    unless current_step == @user.registration_step
      redirect_to case @user.registration_step
      when 2 then step_2_path
      when 3 then step_3_path
      when 4 then step_4_path
      when 5 then step_5_path
      else page_not_found_path
      end
    end
  end

end
