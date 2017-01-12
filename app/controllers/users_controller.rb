class UsersController < ApplicationController
  before_action :still_signed_in
  before_action :validate_instructor, only: [ :show, :index ]
  before_action :validate_admin, except: [ :show, :index ]

  def show
    @user = User.find(params[:id])
  end

  def index
    @users = User.order(created_at: :desc)
    @users = @users.by_fuzzy_text(params[:by_fuzzy_text]) if params[:by_fuzzy_text]
    @users = @users.page(params[:page])

    respond_to do |format|
      format.json { render json: @users.to_json(include: :dependents) }
      format.html
    end
  end

  def attendance
    @athletes = User[params[:id]].athletes
  end

  def update_notifications
    user = User.find(params[:id])
    user.notifications.blow!
    params[:notify].each do |attribute, value|
      user.notifications.update(attribute => true)
    end
    redirect_to :back
  end

  def update_credits
    user = User.find(params[:id])
    user.credits += params[:adjust].to_i
    if user.save
      redirect_to :back, notice: 'User successfully updated.'
    else
      redirect_to :back, alert: 'There was a problem updating the user.'
    end
  end

  def update_trials
    user = User.find(params[:id])
    athlete = user.athletes.find(params[:athlete_id])
    if params[:num].to_i < 0
      params[:num].to_i.abs.times do
        athlete.trial.use!
      end
    else
      params[:num].to_i.abs.times do
        athlete.trial_classes.create
      end
    end
    redirect_to :back
  end

  def destroy
    if params[:confirmation] == "DELETE"
      User.find(params[:id]).destroy
      redirect_to recent_users_path, notice: "User successfully deleted."
    else
      redirect_to recent_users_path, notice: "Sorry, DELETE was not entered correctly. User still exists."
    end
  end

end
