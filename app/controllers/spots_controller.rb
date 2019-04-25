class SpotsController < ApplicationController
  before_action :load_spot, except: [:index, :new, :create]
  before_action :validate_admin, except: [:index, :show]

  def show
    @instructors = @spot.instructors.distinct
  end

  def index
    @spots = Spot.all
  end

  def new
    @spot = Spot.new
  end

  def create
    @spot = Spot.new(spot_params)
    if @spot.save
      redirect_to spot_path(@spot), notice: 'Spot has been successfully created!'
    else
      redirect_to spot_path(@spot), notice: 'There was an issue creating the spot.'
    end
  end

  def update
    if @spot.update(spot_params)
      redirect_to spot_path(@spot), notice: 'Spot has been successfully updated!'
    else
      redirect_to spot_path(@spot), notice: 'There was an issue updating the spot.'
    end
  end

  def destroy
    if @spot.destroy
      redirect_to spots_path, notice: 'Spot has been successfully destroyed!'
    else
      redirect_to spots_path, notice: 'There was an issue destroying the spot.'
    end
  end

  private

  def spot_params
    params.require(:spot).permit(:title, :description, :location, :lon, :lat)
  end

  def load_spot
    @spot = Spot.find(params[:id])
  end

  def validate_admin
    unless current_user && current_user.is_admin?
      if user_signed_in?
        redirect_to new_user_session_path, alert: "You must be an Admin to view this page."
      else
        redirect_to account_path, alert: "You must be an Admin to view this page."
      end
    end
  end
end
