# == Schema Information
#
# Table name: attendances
#
#  id             :integer          not null, primary key
#  dependent_id   :integer
#  user_id        :integer
#  event_id       :integer
#  location       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  type_of_charge :string
#  sent           :boolean          default(FALSE)
#

# TODO Rename associations to be better
class Attendance < ActiveRecord::Base

  belongs_to :dependent
  belongs_to :user
  belongs_to :event

  def athlete; dependent; end
  def instructor; user; end

  def sent!
    self.update(sent: true)
  end

end
