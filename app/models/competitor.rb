# == Schema Information
#
# Table name: competitors
#
#  id               :integer          not null, primary key
#  athlete_id       :integer
#  competition_id   :integer
#  full_name        :string
#  birthdate        :date
#  years_training   :string
#  instagram_handle :string
#  song             :string
#  bio              :string
#  stripe_charge_id :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Competitor < ApplicationRecord
  belongs_to :athlete
  belongs_to :competition
end
