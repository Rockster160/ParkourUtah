# == Schema Information
#
# Table name: subscriptions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  event_schedule_id :integer
#

# TODO Rename me to EventSubscription
class Subscription < ActiveRecord::Base

  belongs_to :event_schedule
  belongs_to :user

end
