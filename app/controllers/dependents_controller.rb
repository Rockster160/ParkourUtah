class DependentsController < ApplicationController
  layout 'application', except: [:secret]

  def new
    @dependent = Dependent.new
  end

  def create
    athletes = params[:athletes].map { |param| Dependent.find_or_create_by_name(param, current_user) }
    athlete_ids = []
    athletes.each do |athlete|
      old_waiver = athlete.waiver
      if old_waiver
        if old_waiver.expires_soon?
          athlete_ids << create_waiver("update", athlete.id).id
        else
          flash[:alert] = "#{athlete.full_name} already has an active waiver."
        end
      else
        athlete_ids << create_waiver("create", athlete.id).id
      end
    end
    flash[:notice] = "Success! Now fill out a waiver to get the Athlete Access Codes."
    redirect_to edit_user_registration_path
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

  def sign_waiver
    ::NewAthleteInfoMailerWorker.perform_async(athlete_ids)
    redirect_to edit_user_registration_path
  end

  def create_waiver(verb, dependent_id)
    athlete = Dependent.find(dependent_id)
    new_waiver = athlete.waiver.new(signed_for: athlete.full_name)
    if new_waiver.save
      flash[:notice] = case verb
      when "create"
        athlete.generate_pin
        "Congratulations! Enjoy a free class for #{athlete.full_name}. An email has been sent to you containing the ID and Pin used to attend class."
      when "update" then "#{athlete.full_name}'s waiver has been updated."
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
