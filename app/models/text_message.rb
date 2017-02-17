# == Schema Information
#
# Table name: text_messages
#
#  id                    :integer          not null, primary key
#  instructor_id         :integer
#  read_by_instructor    :boolean          default(FALSE)
#  sent_to_user          :boolean
#  stripped_phone_number :string
#  body                  :text
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class TextMessage < ActiveRecord::Base
  belongs_to :instructor, class_name: "User", optional: true

  before_validation :strip_phone_number
  validate :phone_number_length
  validates_presence_of :body

  def read!
    update(read_by_instructor: true)
  end

  def user
    User.where("REGEXP_REPLACE(phone_number, '[^\\d]', '', 'g') ILIKE ?", "%#{stripped_phone_number.last(10)}").first
  end

  # Messages receivable? Show before allowing an instructor to send a message

  def deliver
    SmsMailerWorker.perform_async(stripped_phone_number, body)
  end

  def phone_number
    self.stripped_phone_number
  end
  def phone_number=(new_phone)
    self.stripped_phone_number = new_phone
  end

  private

  def strip_phone_number
    self.stripped_phone_number = stripped_phone_number.gsub(/[^\d]/, "")
  end

  def phone_number_length
    unless stripped_phone_number.length >= 10
      errors.add(:stripped_phone_number, "must contain at least 10 digits.")
    end
  end
end
