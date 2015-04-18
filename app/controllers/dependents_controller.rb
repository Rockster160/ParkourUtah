   class DependentsController < ApplicationController
  layout 'application', except: [:secret]

  def new
    @dependent = Dependent.new
  end

  def create
    if params[:athletes]
      potentials = params[:athletes].count
      athletes = params[:athletes].map { |param| Dependent.find_or_create_by_name_and_dob(param, current_user) }
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

  def waiver
    @waiver = Waiver.new
  end

  def waivers
    @athletes = Dependent.where(user_id: current_user.id).select { |athlete| !(athlete.waiver) || !(athlete.waiver.is_active?) }
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

  private

  def dependent_params
    params[:dependent][:emergency_contact] = params[:dependent][:emergency_contact].split('').map {|x| x[/\d+/]}.compact.join('')
    params.require(:dependent).permit(:full_name, :emergency_contact, :athlete_pin, :user_id)
  end

  def waiver_params
    params.require(:waiver).permit(:signed, :athlete_id, :signed_for, :signed_by)
  end

end
