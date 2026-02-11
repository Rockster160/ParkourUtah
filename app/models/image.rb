# == Schema Information
#
# Table name: images
#
#  id         :integer          not null, primary key
#  spot_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Image < ApplicationRecord
  belongs_to :spot, optional: true

  has_one_attached :file
end
