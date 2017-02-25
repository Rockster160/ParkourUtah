# == Schema Information
#
# Table name: event_subscriptions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  event_schedule_id :integer
#

class EventSubscription < ApplicationRecord

  belongs_to :event_schedule
  belongs_to :user

end
