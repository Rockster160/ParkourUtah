class ContactRequestsController < ApplicationController
  before_action :validate_admin

  def index
    params[:show_blocked_requests] ||= "hide"
    @contacts = ContactRequest.order(created_at: :desc).page(params[:page])
    @contacts = @contacts.by_fuzzy_text(params[:by_fuzzy_text]) if params[:by_fuzzy_text].present?
    @contacts = @contacts.where(success: true) if params[:show_blocked_requests] == "hide"

    @current_filter = params.permit(:by_fuzzy_text, :show_blocked_requests).to_h.symbolize_keys
  end

  def show
    @contact = ContactRequest.find(params[:id])
  end

end
