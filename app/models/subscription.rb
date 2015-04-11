# == Schema Information
#
# Table name: subscriptions
#
#  id       :integer          not null, primary key
#  user_id  :integer
#  event_id :integer
#

class Subscription < ActiveRecord::Base

  belongs_to :event
  belongs_to :user

end
