class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_action :merge_carts
  before_action :logit

  def after_sign_in_path_for(resource)
    step_2_path
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
    CustomLogger.log_request(request, current_user)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :avatar
    devise_parameter_sanitizer.for(:account_update) << :avatar_2
    devise_parameter_sanitizer.for(:account_update) << :bio
    devise_parameter_sanitizer.for(:account_update) << :phone_number
    devise_parameter_sanitizer.for(:sign_up) << :first_name
  end
end
