class DependentsController < ApplicationController
  layout 'application', except: [:secret]

  def new
    @dependent = Dependent.new
  end

  def create
    current_user.dependents.create(dependent_params)
    flash[:notice] = "Success! Now fill out a waiver to get an Athlete ID."
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
    waiver = Waiver.new(waiver_params.merge(dependent_id: params[:dependent_id]))
    if waiver.valid?
      waiver.save
      Dependent.find(params[:dependent_id]).generate_pin
      flash[:notice] = "Waiver has been filled out. See you in class!"
    else
      flash[:alert] = waiver.errors.messages.values.first.first
    end
    redirect_to edit_user_registration_path
  end

  def show
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
