class EventController < ApplicationController
  # vefore_action :authenticate_user! only: { :create, :delete }
  # vefore_action :authenticate_mod/admin only: { :create, :delete }
  # https://github.com/plataformatec/devise#strong-parameters

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
  end

  def create
    Event.create(event_params)
  end

  private

  def event_params
    params.require(:event).permit(:title, :host, :cost, :description, :city,
                                :address, :location_instructions, :class_name)
  end
end
