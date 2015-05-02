class RegistrationsController < ApplicationController
  before_action :verify_user_signed_in

  def step_2
  end

  def step_3
  end

  def step_4
  end

  def step_5
  end

  def post_step_2
    notification = update_notifications
    address = current_user.address.update(address_params)
    ec_contact = current_user.emergency_contacts.new(ec_contact_params)
    contact = ec_contact.save!
    if notification && address && contact
      redirect_to step_3_path, notice: "Success!"
    else
      redirect_to :back, alert: "Something went wrong."
    end
  end

  def update_notifications
    return true
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
      if validate_attributes(athlete[1])
        valid << current_user.dependents.create(
          full_name: athlete[1][:name],
          date_of_birth: Dependent.format_dob(athlete[1][:dob]),
          athlete_pin: athlete[1][:pin]
        )
      end
    end
    if valid.count == 1
      redirect_to step_4_path, notice: "Success! #{valid.count} waiver created."
    elsif valid.count > 1
      redirect_to step_4_path, notice: "Success! #{valid.count} waivers created."
    else
      redirect_to :back, alert: "An error occurred."
    end
  end

  def validate_attributes(athlete)
    all_good = true
    all_good = false unless athlete[:name].length > 0
    all_good = false unless athlete[:dob].length == 10
    all_good = false unless athlete[:code].length == 4
    all_good
  end

  def create_athletes

  end

  def sign_waiver
    athlete_ids = params[:athletes].map do |id, code|
      athlete = Dependent.find(id)
      athlete.update(athlete_pin: code)
      old_waiver = athlete.waiver
      update = false
      if old_waiver
        if old_waiver.expires_soon?
          create_waiver("update", athlete.id)
          update = true
        end
      else
        create_waiver("create", athlete.id)
        update = true
      end
      update == true ? id : nil
    end
    ::NewAthleteInfoMailerWorker.perform_async(athlete_ids.compact)
    ::NewAthleteNotificationMailerWorker.perform_async("FIXME")
    redirect_to edit_user_registration_path
  end

  def create_waiver(verb, dependent_id)
    athlete = Dependent.find(dependent_id)
    new_waiver = Waiver.new(
                  signed_for: athlete.full_name,
                  signed_by: params[:signed_by],
                  signed: true,
                  dependent_id: athlete.id
    )
    if new_waiver.save
      flash[:notice] = case verb
      when "create"
        athlete.generate_pin
        "Congratulations! Enjoy a class on us for your new athletes. An email has been sent to you containing the ID and Pin used to attend class."
      when "update" then "Thanks! Your waiver has been updated."
      else "Waiver created."
      end
      athlete
    else
      flash[:alert] = new_waiver.errors.messages.values.first.first
      nil
    end
  end

  def post_step_4
    redirect_to :back
  end

  def post_step_5
    redirect_to :back
  end

  private

    def verify_user_signed_in
      redirect_to root_path, alert: "Must be signed in to do that." unless current_user
    end

end
