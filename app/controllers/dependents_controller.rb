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
