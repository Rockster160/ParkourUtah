class AthletesController < ApplicationController
  before_action :validate_user_signed_in
  layout 'application', except: [ :secret ]

  def index
    @athletes = Athlete.by_most_recent(:created_at)
    @athletes = @athletes.by_fuzzy_text(params[:by_fuzzy_text]) if params[:by_fuzzy_text]

    respond_to do |format|
      format.json { render json: @athletes }
      format.html
    end
  end

  def new
    @athlete = Athlete.new
  end

  def create
    if params[:athletes]
      potentials = params[:athletes].count
      athletes = params[:athletes].map { |param| Athlete.find_or_create_by_name_and_dob(param[1], current_user) }
      if potentials == athletes.compact.count
        flash[:notice] = "Success! Now fill out a waiver to get the Athlete Access Codes."
      else
        flash[:alert] = "There was an error creating one or more of the athletes."
      end
      redirect_to waivers_path
    else
      flash[:alert] = "There was an error creating one or more of the athletes."
      redirect_back fallback_location: root_path
    end
  end

  def update_photo
    athlete = Athlete.find(params[:id])

    if athlete.update(athlete_photo: params[:athlete_photo])
      redirect_back fallback_location: root_path, notice: 'Image successfully updated.'
    else
      redirect_back fallback_location: root_path, alert: 'There was an error updating the image.'
    end
  end

  def update
    pin = params[:fast_pass_pin]
    confirm = params[:confirm_fast_pass_pin]
    if pin == confirm
      if Athlete.find(params[:fast_pass_id]).update(fast_pass_pin: pin)
        flash[:notice] = "Pin successfully updated."
        redirect_to account_path
      else
        flash[:alert] = "There was an error saving your pin."
        redirect_back fallback_location: root_path
      end
    else
      flash[:alert] = "The pins did not match. No changes were made."
      redirect_back fallback_location: root_path
    end
  end

  def verify
    params[:athlete].each do |athlete_id, codes|
      athlete = Athlete.find(athlete_id)
      if athlete.fast_pass_id == codes[:fast_pass_id].to_i && athlete.fast_pass_pin == codes[:fast_pass_pin].to_i
        if athlete.update(verified: true)
          athlete.sign_up_verified
        end
      end
    end
    redirect_to account_path
  end

  def assign_subscription
    athlete = Athlete.find(params[:athlete_id])
    user = athlete.user

    if user.recurring_subscriptions.unassigned.count > 0
      subscription = user.recurring_subscriptions.unassigned.last
      if subscription.assign_to_athlete(athlete)
        redirect_to account_path, notice: "Successfully assigned! This subscription will auto-charge each month from now on."
      else
        redirect_to account_path, alert: "Failed to add the Subscription. The start and expiration dates will not be set until successfully assigned."
      end
    else
      redirect_to account_path, alert: "No subscriptions to assign"
    end
  end

  def update_waiver
    @valid = []
    @new_fast_pass_ids = []

    add_new_athletes_from_waivers

    update_existing_athlete_waivers

    if @new_fast_pass_ids.count > 0
      ApplicationMailer.new_athlete_info_mail(@new_fast_pass_ids).deliver_later
    end
    if @valid.count == 1
      redirect_to step_4_path, notice: "Success! #{@valid.count} waiver updated/created."
    elsif @valid.count > 1
      redirect_to step_4_path, notice: "Success! #{@valid.count} waivers updated/created."
    else
      redirect_back fallback_location: root_path, alert: "An error occurred."
    end
  end

  def update_existing_athlete_waivers
    if params[:update_athlete].present?
      params[:update_athlete].each do |athlete_id, athlete_params|
        athlete = Athlete.find(athlete_id)
        if validate_athlete_attributes(athlete_params)
          athlete.waivers.create({
            signed_for: athlete.full_name,
            signed_by: params[:signed_by],
          }).sign!
          @valid << athlete
        end
      end
    end
  end

  def add_new_athletes_from_waivers
    if params[:athlete].present?
      params[:athlete].each do |token, athlete|
        if validate_athlete_attributes(athlete)
          new_athlete = current_user.athletes.create({
            full_name: athlete[:name],
            date_of_birth: athlete[:dob],
            fast_pass_pin: athlete[:code]
          })
          new_athlete.waivers.create({
            signed_for: new_athlete.full_name,
            signed_by: params[:signed_by],
          })
          if new_athlete.sign_waiver!
            @new_fast_pass_ids << new_athlete.id
            new_athlete.generate_pin
            @valid << new_athlete
          end
        end
      end
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
    athlete = Athlete.find(params[:fast_pass_id])
    athlete.destroy
    redirect_back fallback_location: root_path, notice: "Athlete successfully deleted."
  end

  def reset_pin
    if current_user.valid_password?(params[:password])
      @athlete = Athlete.find(params[:id])
      if params[:fast_pass_pin] == params[:pin_confirmation] && @athlete.update(fast_pass_pin: params[:fast_pass_pin].to_i)
        redirect_to account_path, notice: "Successfully updated pin for #{@athlete.full_name}."
      else
        redirect_to account_path, alert: 'The pins you entered did not match.'
      end
    else
      redirect_to account_path, alert: 'Sorry. Your password was not correct.'
    end
  end

  def destroy
    athlete = Athlete.find(params[:id])
    if athlete.destroy
      redirect_back fallback_location: root_path, notice: "Athlete successfully deleted."
    else
      redirect_back fallback_location: root_path, notice: "There was a problem destroying the athlete."
    end
  end

  private

  def athlete_params
    params[:athlete][:emergency_contact] = params[:athlete][:emergency_contact].split('').map {|x| x[/\d+/]}.compact.join('')
    params.require(:athlete).permit(:full_name, :emergency_contact, :fast_pass_pin, :user_id)
  end

  def waiver_params
    params.require(:waiver).permit(:signed, :fast_pass_id, :signed_for, :signed_by)
  end

end
