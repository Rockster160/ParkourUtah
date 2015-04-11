# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  first_name             :string           default(""), not null
#  last_name              :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  role                   :integer          default(0)
#  created_at             :datetime
#  updated_at             :datetime
#  avatar_file_name       :string
#  avatar_content_type    :string
#  avatar_file_size       :integer
#  avatar_updated_at      :datetime
#  avatar_2_file_name     :string
#  avatar_2_content_type  :string
#  avatar_2_file_size     :integer
#  avatar_2_updated_at    :datetime
#  bio                    :text
#  credits                :integer          default(0)
#  phone_number           :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  instructor_position    :integer
#  payment_multiplier     :integer          default(3)
#  stats                  :string
#  title                  :string
#  nickname               :string
#  email_subscription     :boolean          default(FALSE)
#  stripe_id              :string
#  date_of_birth          :datetime
#  drivers_license_number :string
#  drivers_license_state  :string
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
