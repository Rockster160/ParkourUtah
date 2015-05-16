class RegistrationsController < ApplicationController
  before_action :verify_user_signed_in

  def step_2
    redirect_user_to_correct_step(2)
  end

  def step_3
    redirect_user_to_correct_step(3)
  end

  def step_4
    redirect_user_to_correct_step(4)
    @athletes = current_user.dependents.select {|athlete| athlete.signed_waiver? == false }
  end

  def step_5
    redirect_user_to_correct_step(5)
    if current_user.registration_step == 5
      # current_user.update(registration_complete: true)
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
      redirect_to :back, alert: "Something went wrong."
    end
  end

  def user_params
    params[:user][:phone_number] = params[:user][:phone]
    params.require(:user).permit(:phone_number, :email)
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
    params[:athlete].each do |athlete|
      if validate_athlete_attributes(athlete[1])
        new_athlete = current_user.dependents.create(
          full_name: athlete[1][:name],
          date_of_birth: athlete[1][:dob],
          athlete_pin: athlete[1][:code]
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
      redirect_to :back, alert: "An error occurred."
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
      redirect_to :back, alert: "Something went wrong."
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
    ::NewAthleteInfoMailerWorker.perform_async(approved.compact)
    ::NewAthleteNotificationMailerWorker.perform_async(approved.compact)
    current_user.update(registration_step: 5)
    redirect_to step_5_path
  end

  private

    def verify_user_signed_in
      unless current_user
        redirect_to root_path, alert: "Must be signed in to do that."
      else
        if current_user.registration_complete?
          redirect_to edit_user_registration_path
        end
      end
    end

    def redirect_user_to_correct_step(current_step)
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
