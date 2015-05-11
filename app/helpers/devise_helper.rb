module DeviseHelper

  # Hacky way to translate devise error messages into devise flash error messages
  def devise_error_messages!
    if resource.errors.full_messages.any?
        flash.now[:alert] = resource.errors.full_messages.first
    end
    return ''
  end
end
