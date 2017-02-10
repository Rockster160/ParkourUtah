class RegistrationsController < ApplicationController
  before_action :verify_user_signed_in
  before_action :redirect_user_to_correct_step

  def step_4
    @athletes = current_user.dependents.select {|athlete| athlete.signed_waiver? == false }
  end

  def step_5
    if current_user.registration_step == 5
      current_user.update(registration_complete: true)
    end
  end

  def post_step_2
    update_self = current_user.update(user_params)
    notification = update_notifications
    address = current_user.address.update(address_params)
    ec_contact = current_user.emergency_contacts.new(ec_contact_params)
    contact = ec_contact.save!
    if update_self && notification && address && contact
      current_user.update(registration_step: 3)
      redirect_to step_3_path, notice: "Success!"
    else
      redirect_back fallback_location: root_path, alert: "Something went wrong."
    end
  end

  def user_params
    params[:user][:phone_number] = params[:user][:phone]
    params[:user][:referrer] = params[:user][:referrer_dropdown] == "Word of Mouth" ? params[:user][:referrer_text] : params[:user][:referrer_dropdown]
    params.require(:user).permit(:phone_number, :email, :referrer)
  end

  def update_notifications
    new_value = params[:smsalert] ? true : false
    current_user.notifications.update_attributes(
      text_class_reminder: new_value,
      text_low_credits: new_value,
      text_waiver_expiring: new_value
    )
  end

  def address_params
    params.require(:address).permit(:line1, :line2, :city, :state, :zip)
  end

  def ec_contact_params
    params.require(:ec_contact).permit(:name, :number)
  end

  def post_step_3
    valid = []
    params[:athlete].each do |token, athlete|
      if validate_athlete_attributes(athlete)
        new_athlete = current_user.dependents.create(
          full_name: athlete[:name],
          date_of_birth: athlete[:dob],
          athlete_pin: athlete[:code]
        )
        new_athlete.waivers.create(
          signed_for: new_athlete.full_name,
          signed_by: params[:signed_by],
        )
        valid << new_athlete
      end
    end
    if valid.count == 1
      current_user.update(registration_step: 4)
      redirect_to step_4_path, notice: "Success! #{valid.count} waiver created."
    elsif valid.count > 1
      current_user.update(registration_step: 4)
      redirect_to step_4_path, notice: "Success! #{valid.count} waivers created."
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
    update_self = current_user.update(user_params)
    notification = update_notifications
    address = current_user.address.update(address_params)
    ec_contact = current_user.emergency_contacts.new(ec_contact_params)
    contact = ec_contact.save!
    athletes = update_athletes
    if update_self && notification && address && contact && update_athletes
      redirect_to step_4_path, notice: "We've updated the requested changes."
    else
      redirect_back fallback_location: root_path, alert: "Something went wrong."
    end
  end

  def update_athletes
    valid = true
    params[:athlete].each do |athlete_id, values|
      athlete = Dependent.find(athlete_id)
      temp_valid = athlete.update(
        full_name: values[:name],
        date_of_birth: values[:dob],
        athlete_pin: values[:code]
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
      athlete = Dependent.find(id)
      if athlete.sign_waiver!
        approved << athlete.id
        athlete.generate_pin
      end
    end
    
    slack_message = "New User: <#{admin_user_path(current_user)}|#{current_user.id} #{current_user.email}>\n"
    current_user.athletes.each do |athlete|
      slack_message << "#{athlete.id} #{athlete.full_name} - Athlete ID: #{athlete.zero_padded(athlete.athlete_id, 4)} Pin: #{athlete.zero_padded(athlete.athlete_pin, 4)}\n"
    end
    slack_message << "Referred By: #{current_user.referrer}"
    channel = Rails.env.production? ? "#new-users" : "#slack-testing"
    SlackNotifier.notify(slack_message, channel)

    ::NewAthleteInfoMailerWorker.perform_async(approved.compact)
    current_user.update(registration_step: 5)
    redirect_to step_5_path
  end

  private

    def verify_user_signed_in
      unless current_user
        redirect_to root_path, alert: "Must be signed in to do that."
      else
        if current_user.registration_complete?
          redirect_to edit_user_path
        end
      end
    end

    def current_step
      params[:action].gsub(/[^0-9]/, '').to_i
    end

    def redirect_user_to_correct_step
      unless current_step == current_user.registration_step
        redirect_to case current_user.registration_step
        when 2 then step_2_path
        when 3 then step_3_path
        when 4 then step_4_path
        when 5 then step_5_path
        else page_not_found_path
        end
      end
    end

end
