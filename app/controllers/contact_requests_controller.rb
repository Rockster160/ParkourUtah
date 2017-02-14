class ContactRequestsController < ApplicationController
  before_action :validate_admin

  def index
    @contacts = ContactRequest.order(created_at: :desc).page(params[:page])
    @contacts = @contacts.by_fuzzy_text(params[:by_fuzzy_text]) if params[:by_fuzzy_text].present?
    @contacts = @contacts.where(success: true) if params[:show_blocked_requests] == "hide"

    @current_filter = params.to_hash.symbolize_keys.slice(:by_fuzzy_text, :show_blocked_requests)
  end

  def show
    @contact = ContactRequest.find(params[:id])
  end

end
