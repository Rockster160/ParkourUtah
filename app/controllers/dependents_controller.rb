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

  def waiver
    @waiver = Waiver.new
  end

  def sign_waiver
    waiver = Waiver.create(waiver_params)
    if waiver
      waiver.dependent_id = params[:dependent_id]
      Dependent.find(params[:dependent_id]).generate_pin
      waiver.save
      flash[:notice] = "Waiver has been filled out. See you in class!"
    else
      flash[:alert] = "There was an error creating your waiver."
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
    params.require(:waiver).permit(:signed, :athlete_id)
  end

end
