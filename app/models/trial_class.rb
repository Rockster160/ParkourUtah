# == Schema Information
#
# Table name: trial_classes
#
#  id         :integer          not null, primary key
#  athlete_id :integer
#  used       :boolean          default(FALSE)
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TrialClass < ApplicationRecord
  belongs_to :athlete

  def use!
    self.used = true
    self.used_at = Time.zone.now
    self.save
  end
end
