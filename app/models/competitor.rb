# == Schema Information
#
# Table name: competitors
#
#  id               :integer          not null, primary key
#  athlete_id       :integer
#  competition_id   :integer
#  years_training   :string
#  instagram_handle :string
#  song             :string
#  bio              :string
#  stripe_charge_id :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  approved_at      :datetime
#  age              :integer
#  sort_order       :integer
#

class Competitor < ApplicationRecord
  belongs_to :athlete
  belongs_to :competition
  has_many :competition_judgements

  scope :youth, -> { where("age < 14") }
  scope :adult, -> { where("age >= 14") }

  delegate :full_name, to: :athlete

  def rank(category=nil)
    idx = competition.ranked_competitors(category).index(self)
    return if idx.nil?
    idx + 1
  end

  def score(category=nil)
    if category.to_s == "overall_impression"
      (competition_judgements.sum(:overall_impression) / competition_judgements.count).round(1)
    elsif category.present?
      competition_judgements.find_by(category: CompetitionJudgement.categories[category]).try(:category_score)
    else
      competition_judgements.sum(:category_score) + score(:overall_impression)
    end
  end

  def position
    sort_order
  end

  private

  def set_initial_values
    self.age = age = athlete.age || 0
    group = age < 18 ? :youth : :adult
    self.sort_order = self.class.send(group).maximum(:sort_order).to_i + 1
  end
end
