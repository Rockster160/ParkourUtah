   class DependentsController < ApplicationController
  layout 'application', except: [:secret]

  def new
    @dependent = Dependent.new
  end

  def create
    if params[:athletes]
      potentials = params[:athletes].count
      athletes = params[:athletes].map { |param| Dependent.find_or_create_by_name_and_dob(param[1], current_user) }
      if potentials == athletes.compact.count
        flash[:notice] = "Success! Now fill out a waiver to get the Athlete Access Codes."
      else
        flash[:alert] = "There was an error creating one or more of the athletes."
      end
      redirect_to waivers_path
    else
      flash[:alert] = "There was an error creating one or more of the athletes."
      redirect_to :back
    end
  end

  def update
    pin = params[:athlete_pin]
    confirm = params[:confirm_athlete_pin]
    if pin == confirm
      if Dependent.find(params[:athlete_id]).update(athlete_pin: pin)
        flash[:notice] = "Pin successfully updated."
        redirect_to edit_user_registration_path
      else
        flash[:alert] = "There was an error saving your pin."
        redirect_to :back
      end
    else
      flash[:alert] = "The pins did not match. No changes were made."
      redirect_to :back
    end
  end

  def verify
    params[:athlete].each do |athlete_id, codes|
      athlete = Dependent.find(athlete_id)
      if athlete.athlete_id == codes[:athlete_id].to_i && athlete.athlete_pin == codes[:athlete_pin].to_i
        if athlete.update(verified: true)
          athlete.sign_up_verified
        end
      end
    end
    redirect_to edit_user_registration_path
  end

  def update_waiver
    valid = []
    new_athlete_ids = []
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
        if new_athlete.sign_waiver!
          new_athlete_ids << new_athlete.id
          new_athlete.generate_pin
          valid << new_athlete
        end
      end
    end if params[:athlete]
    params[:update_athlete].each do |athlete_id, athlete_params|
      athlete = Dependent.find(athlete_id)
      if validate_athlete_attributes(athlete_params)
        athlete.waivers.create(
          signed_for: athlete.full_name,
          signed_by: params[:signed_by],
        ).sign!
        valid << athlete
      end
    end if params[:update_athlete]
    if new_athlete_ids.count > 0
      ::NewAthleteInfoMailerWorker.perform_async(new_athlete_ids)
      ::NewAthleteNotificationMailerWorker.perform_async(new_athlete_ids)
    end
    if valid.count == 1
      redirect_to step_4_path, notice: "Success! #{valid.count} waiver updated/created."
    elsif valid.count > 1
      redirect_to step_4_path, notice: "Success! #{valid.count} waivers updated/created."
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

  def sign_waiver
    @athletes = current_user.athletes_where_expired_past_or_soon
  end

  def delete_athlete
    athlete = Dependent.find(params[:athlete_id])
    athlete.destroy
    redirect_to :back, notice: "Athlete successfully deleted."
  end

  def show
  end

  def forgot_pin_or_id
    flash[:notice] = "We just sent you an email with instructions on what to do next."
    athlete_id = params[:athlete_id]
    ::PinResetMailerWorker.perform_async(athlete_id)
    redirect_to edit_user_registration_path
  end

  def reset_pin
    @athlete = Dependent.find(params[:athlete_id])
    unless current_user == @athlete.user
      redirect_to root_path, alert: "Sorry, you must be the parent or guardian of the athlete to do that."
    end
  end

  def destroy
    athlete = Dependent.find(params[:id])
    if athlete.attendances.count < 2
      # athlete.user.update(credits: athlete.user.credits - (ENV["PKUT_CLASS_PRICE"].to_i * (2 - athlete.attendances.count)))
    end
    if athlete.destroy
      if current_user.is_admin?
        redirect_to recent_users_path, motice: "Athlete successfully deleted."
      else
        redirect_to edit_user_registration_path, motice: "Athlete successfully deleted."
      end
    else
      redirect_to :back, motice: "There was a problem destroying the athlete."
    end
  end

  private

  def dependent_params
    params[:dependent][:emergency_contact] = params[:dependent][:emergency_contact].split('').map {|x| x[/\d+/]}.compact.join('')
    params.require(:dependent).permit(:full_name, :emergency_contact, :athlete_pin, :user_id)
  end

  def waiver_params
    params.require(:waiver).permit(:signed, :athlete_id, :signed_for, :signed_by)
  end

end
