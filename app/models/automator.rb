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
    Automator.create unless first
    first.update(open: true)
  end

  def self.deactivate!
    Automator.create unless first
    first.update(open: false)
  end

  def self.open?
    Automator.create unless first
    first.open
  end
end
