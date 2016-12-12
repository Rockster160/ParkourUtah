# == Schema Information
#
# Table name: venmos
#
#  id            :integer          not null, primary key
#  access_token  :string
#  refresh_token :string
#  expires_at    :datetime
#  username      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Venmo < ActiveRecord::Base

  def expired?
    Time.zone.now > expires_at
  end
end
