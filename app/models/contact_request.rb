# == Schema Information
#
# Table name: contact_requests
#
#  id         :integer          not null, primary key
#  user_agent :string
#  phone      :string
#  name       :string
#  email      :string
#  body       :string
#  success    :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContactRequest < ActiveRecord::Base
end
