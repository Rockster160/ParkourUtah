class AdminsController < ApplicationController
  include EmailHelper
  before_action :still_signed_in
  before_action :validate_admin, except: [ :dashboard ]
  before_action :validate_instructor, only: [ :dashboard ]

  EmailBody = Struct.new(:subject, :body, :recipients, :email_type)

  def dashboard
    @classes = EventSchedule.events_today
  end

  def purchase_history
    @line_item_ids = (params[:line_item_ids].try(:compact) || []).map(&:to_i)
    line_items = LineItem.where(id: @line_item_ids)
    @items_with_users = line_items.map do |line_item|
      {
        line_item_id: line_item.id,
        users: line_item.users_who_purchased
      }
    end
  end

  private

  def decoded_email_params
    if params[:encoded] == 'true'
      [Base64.urlsafe_decode64(params[:subject] || ''), Base64.urlsafe_decode64(params[:body] || ''), Base64.urlsafe_decode64(params[:recipients] || ''), Base64.urlsafe_decode64(params[:email_type] || '')]
    else
      [params[:subject], params[:body], params[:recipients], params[:email_type]]
    end
  end

end
