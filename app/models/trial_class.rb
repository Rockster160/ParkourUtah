# == Schema Information
#
# Table name: trial_classes
#
#  id           :integer          not null, primary key
#  dependent_id :integer
#  used         :boolean          default(FALSE)
#  used_at      :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class TrialClass < ActiveRecord::Base
  belongs_to :dependent

  def use!
    self.used = true
    self.used_at = DateTime.current
    self.save
  end
end
