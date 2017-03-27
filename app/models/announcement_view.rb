# == Schema Information
#
# Table name: announcement_views
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  announcement_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class AnnouncementView < ApplicationRecord
  belongs_to :user
  belongs_to :announcement
end
