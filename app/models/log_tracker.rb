# == Schema Information
#
# Table name: log_trackers
#
#  id          :integer          not null, primary key
#  user_agent  :string
#  ip_address  :string
#  http_method :string
#  url         :string
#  params      :string
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class LogTracker < ApplicationRecord
  belongs_to :user, optional: true

  after_create_commit :broadcast_creation

  def params_json
    JSON.parse(params.gsub("=>", ":"))
  end

  private

  def broadcast_creation
    rendered_message = LogTrackersController.render partial: 'log_trackers/logger_row', locals: { logger: self }
    ActionCable.server.broadcast "logger_channel", { message: rendered_message }
  end

end

# ianlogs = LogTracker.where(user_id: 1031).where("params ILIKE '%fast_pass_id%'").order(created_at: :desc)
# puts ianlogs.map { |lt| "#{lt.created_at.to_formatted_s(:short_with_time)} - Fast Pass ID: #{lt.params_json['fast_pass_id']} Fast Pass Pin: #{lt.params_json['fast_pass_id']}" }
