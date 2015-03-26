class IndexController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    @instructors = User.where("role > ?", 0).sort_by { |u| u.instructor_position }

    all_events = Event.where(nil)
    @events = all_events.group_by { |event| [event.date.month, event.date.day] }
    @cities = all_events.group_by { |event| event.city }.keys
    @classes = all_events.group_by { |event| event.class_name }.keys

    @selected_cities = params[:cities] ? params[:cities] : @cities
    @selected_classes = params[:classes] ? params[:classes] : @classes
  end

  def coming_soon
  end

  def contact
    flash[:notice] = "Thanks! We'll have somebody get in contact with you shortly."
    ::ContactMailerWorker.perform_async(params)
    redirect_to root_path
  end

  def contact_page
  end
end
