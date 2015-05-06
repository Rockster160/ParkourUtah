# == Schema Information
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  email_class_reminder  :boolean          default(FALSE)
#  text_class_reminder   :boolean          default(FALSE)
#  email_low_credits     :boolean          default(FALSE)
#  text_low_credits      :boolean          default(FALSE)
#  email_waiver_expiring :boolean          default(FALSE)
#  text_waiver_expiring  :boolean          default(FALSE)
#

class Notifications < ActiveRecord::Base
  belongs_to :user
  # TODO rename text_class_reminder email_waiver_expiring text_waiver_expiring
end
