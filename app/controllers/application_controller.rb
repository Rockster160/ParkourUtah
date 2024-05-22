class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :pretty_logit, if: -> { should_log? }
  before_action :see_current_user, :merge_carts
  before_action :store_current_location, unless: :devise_controller?

  def flash_message
    flash.now[params[:flash_type]&.to_sym] = params[:message]
    render partial: 'layouts/flashes'
  end

  def after_sign_up_path_for(resource)
    step_2_path
  end

  def merge_carts
    if user_signed_in? && session["cart_id"]
      items_to_add = Cart.find(session["cart_id"].to_i).items.map(&:id)
      current_user.cart.add_items(items_to_add)
      session.delete("cart_id")
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.sanitize(:account_update) { |u| u.permit(:avatar, :avatar_2, :bio, :phone_number) }
    devise_parameter_sanitizer.sanitize(:sign_up) { |u| u.permit(:first_name) }
  end

  def still_signed_in
    current_user.still_signed_in! if current_user
  end

  def validate_user_signed_in
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "You must be logged in to view this page."
    end
  end

  def validate_instructor
    unless current_user && current_user.is_instructor?
      redirect_to account_path, alert: "You are not authorized to view this page."
    end
  end

  def validate_mod
    unless current_user && current_user.is_mod?
      redirect_to account_path, alert: "You are not authorized to view this page."
    end
  end

  def validate_admin
    unless current_user && current_user.is_admin?
      redirect_to account_path, alert: "You are not authorized to view this page."
    end
  end

  def verify_user_is_not_signed_in
    if user_signed_in?
      redirect_to account_path, alert: "You're already signed in!"
    end
  end

  def see_current_user
    Rails.logger.silence do
      if user_signed_in?
        request.env['exception_notifier.exception_data'] = {
          current_user: "#{current_user.id} - #{current_user.email}",
          params: params
        }
      end
    end
  end

  def should_log?
    user_signed_in?
  end

  # Override default from PrettyLogger
  def request_logger
    @request_logger ||= ::PrettyLogger::RequestLogger.new(
      request: request,
      current_user: current_user,
    )
  end

  def store_current_location
    store_location_for(:user, request.url)
  end
end
