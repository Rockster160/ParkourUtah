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
#  sms_receivable        :boolean
#  text_class_cancelled  :boolean          default(FALSE)
#  email_class_cancelled :boolean          default(FALSE)
#  email_newsletter      :boolean          default(TRUE)
#

class Notifications < ApplicationRecord
  include Defaults

  belongs_to :user

  def blow!(str="all")
    case str
    when "text" then change_all_text_to(false)
    when "email" then change_all_email_to(false)
    else
      change_all_text_to(false)
      change_all_email_to(false)
    end
    save
  end

  def change_all_email_to(bool)
    self.email_newsletter = bool
    self.email_class_reminder = bool
    self.email_low_credits = bool
    self.email_waiver_expiring = bool
    self.email_class_cancelled = bool
  end

  def change_all_text_to(bool)
    self.text_class_cancelled = bool
    self.text_class_reminder = bool
    self.text_low_credits = bool
    self.text_waiver_expiring = bool
  end
end
