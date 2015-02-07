class EventController < ApplicationController
  # vefore_action :authenticate_user! only: { :create, :delete }
  # vefore_action :authenticate_mod/admin only: { :create, :delete }
  # https://github.com/plataformatec/devise#strong-parameters

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
    all_events = Event.all.to_a
    @cities = all_events.group_by { |event| event.city }.keys
    @classes = all_events.group_by { |event| event.class_name }.keys
    @mods = User.where("role > ?", 0)
  end

  def create
    raise 'a'
    Event.create(event_params)
  end

  private

  def event_params
    params.require(:event).permit(:title, :host, :cost, :description, :city,
                                :address, :location_instructions, :class_name)
  end
end
