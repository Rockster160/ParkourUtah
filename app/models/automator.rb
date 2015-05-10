# == Schema Information
#
# Table name: automators
#
#  id         :integer          not null, primary key
#  open       :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Automator < ActiveRecord::Base

  def self.activate!
    first.update(open: true)
  end

  def self.deactivate!
    first.update(open: false)
  end

  def self.open?
    first.open
  end
end
