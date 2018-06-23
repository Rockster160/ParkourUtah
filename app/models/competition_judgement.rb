# == Schema Information
#
# Table name: competition_judgements
#
#  id                 :integer          not null, primary key
#  competitor_id      :integer
#  judge_id           :integer
#  category           :integer
#  category_score     :float
#  overall_impression :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class CompetitionJudgement < ApplicationRecord
  belongs_to :competitor
  belongs_to :judge, class_name: "User"

  scope :by_category, ->(category) { where(category: categories[category.to_s.downcase.squish]) }
  scope :youth, -> { joins(:competitor).where("competitors.age < 14") }
  scope :adult, -> { joins(:competitor).where("competitors.age >= 14") }

  validates :category, presence: true

  delegate :competition, to: :competitor
  delegate :athlete,     to: :competitor

  enum category: [:flow, :execution, :creativity, :difficulty]

  after_commit :broadcast

  def broadcast
    ActionCable.server.broadcast "competition_channel", competition.competitor_hash
  end
end
