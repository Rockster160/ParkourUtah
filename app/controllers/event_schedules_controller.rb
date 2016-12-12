class EventSchedulesController < ApplicationController
  before_action :validate_user, only: [ :create, :new ]

  def subscribe
    user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
    user.subscriptions.create(event_schedule_id: params[:id])
    redirect_to :back, notice: "You have successfully subscribed to this event."
  end

  def unsubscribe
    user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
    user.subscriptions.where(event_schedule_id: params[:id]).destroy_all
    redirect_to :back, notice: "You have successfully unsubscribed from this event."
  end

end
