class EventController < ApplicationController
  # vefore_action :authenticate_user! only: { :create, :delete }
  # vefore_action :authenticate_mod/admin only: { :create, :delete }
  # https://github.com/plataformatec/devise#strong-parameters

  def show
    @event = Event.find(params[:id])
  end
end
