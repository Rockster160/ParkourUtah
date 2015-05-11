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
  after_create :set_defaults
  # TODO rename text_class_reminder email_waiver_expiring text_waiver_expiring

  def set_defaults
    self.email_class_reminder = true
    self.text_class_reminder = false
    self.email_low_credits = true
    self.text_low_credits = false
    self.email_waiver_expiring = true
    self.text_waiver_expiring = false
    self.save!
  end

  def blow!(str="all")
    case string
    when "text" then change_all_text_to false
    when "email" then change_all_email_to false
    else
      change_all_text_to false
      change_all_email_to false
    end
  end

  def change_all_email_to(bool)
    self.email_class_reminder = bool
    self.email_low_credits = bool
    self.email_waiver_expiring = bool
  end

  def change_all_text_to(bool)
    self.text_class_reminder = bool
    self.text_low_credits = bool
    self.text_waiver_expiring = bool
  end
end
