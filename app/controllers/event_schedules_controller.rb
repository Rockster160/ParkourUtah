class EventSchedulesController < ApplicationController
  before_action :validate_user, only: [ :create, :new ]

  def index
    @event_schedules = EventSchedule.in_the_future
  end

  def show
    @event_schedule = EventSchedule.find(params[:id])
    @attendances_by_date = @event_schedule.attendances.order(:created_at).group_by { |a| a.event.date }
  end

  def new
    @event_schedule = EventSchedule.new(city: params[:city])
  end

  def edit
    @event_schedule = EventSchedule.find(params[:id])
  end

  def update
    @event_schedule = EventSchedule.find(params[:id])
    if @event_schedule.update(event_schedule_params)
      redirect_to event_schedules_path, notice: "Success!"
    else
      flash.now[:alert] = "Failed."
      render :edit
    end
  end

  def create
    @event_schedule = EventSchedule.new(event_schedule_params)
    if @event_schedule.save
      redirect_to event_schedules_path, notice: "Success!"
    else
      flash.now[:alert] = "Failed."
      render :new
    end
  end

  def subscribe
    user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
    user.event_subscriptions.find_or_create_by(event_schedule_id: params[:id])
    flash[:notice] = "You have successfully subscribed to this event."
    redirect_back fallback_location: root_path
  end

  def unsubscribe
    user = params[:user_id].present? ? User.find(params[:user_id]) : current_user
    user.event_subscriptions.where(event_schedule_id: params[:id]).destroy_all
    flash[:notice] = "You have successfully unsubscribed from this event."
    redirect_back fallback_location: root_path
  end

  def send_message_to_subscribers
    event_schedule = EventSchedule.find(params[:id])
    event_schedule.subscribed_users.each do |user|
      if user.notifications.text_class_cancelled? && user.notifications.sms_receivable?
        Message.text.create(body: params[:message], chat_room_name: user.phone_number, sent_from_id: 0).deliver
      end
      if user.notifications.email_class_cancelled?
        ApplicationMailer.email(user.email, "Message regarding the #{event_schedule.title} class today", params[:message]).deliver_now
      end
    end
    redirect_back fallback_location: root_path, notice: 'Your message has been sent.'
  end

  private

  def validate_user
    unless user_signed_in? && current_user.is_admin?
      flash[:alert] = "You are not permitted to create Events."
      redirect_to root_path
    end
  end

  def event_schedule_params
    params.require(:event_schedule).permit(
      :instructor_id,
      :spot_id,
      :start_str_date,
      :end_str_date,
      :time_of_day,
      :day_of_week,
      :cost,
      :title,
      :description,
      :full_address,
      :city,
      :color,
      :payment_per_student,
      :min_payment_per_session,
      :max_payment_per_session,
      :accepts_unlimited_classes,
      :accepts_trial_classes
    )
  end

end
