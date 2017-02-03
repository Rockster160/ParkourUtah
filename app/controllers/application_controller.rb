class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :merge_carts
  before_action :logit

  def after_sign_in_path_for(resource)
    edit_user_registration_path
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

  def logit
    return CustomLogger.log_blip! if params[:checker]
    CustomLogger.log_request(request, current_user, session['cart_id'])
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :avatar
    devise_parameter_sanitizer.for(:account_update) << :avatar_2
    devise_parameter_sanitizer.for(:account_update) << :bio
    devise_parameter_sanitizer.for(:account_update) << :phone_number
    devise_parameter_sanitizer.for(:sign_up) << :first_name
  end

  def still_signed_in
    current_user.still_signed_in! if current_user
  end

  def validate_instructor
    unless current_user && current_user.is_instructor?
      redirect_to edit_user_registration_path, alert: "You are not authorized to view this page."
    end
  end

  def validate_mod
    unless current_user && current_user.is_mod?
      redirect_to edit_user_registration_path, alert: "You are not authorized to view this page."
    end
  end

  def validate_admin
    unless current_user && current_user.is_admin?
      redirect_to edit_user_registration_path, alert: "You are not authorized to view this page."
    end
  end

  def see_current_user
    Rails.logger.silence do
      if user_signed_in?
        request.env['exception_notifier.exception_data'] = { current_user: "#{current_user.id} - #{current_user.email}" }
      end
    end
  end
end
