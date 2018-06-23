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
  scope :approved, -> { where.not(approved_at: nil) }

  delegate :full_name, to: :athlete

  def youth?; age.to_i < 14; end
  def adult?; age.to_i >= 14; end
  def age_group; age < 14 ? :youth : :adult; end

  def rank(category=nil)
    idx = competition.ranked_competitors(age_group, category).index(self)
    return if idx.nil?
    idx + 1
  end

  def score(category=nil)
    judgments = competition_judgements.send(age_group)
    return if judgments.none?
    if category.to_s == "overall_impression"
      (judgments.sum(:overall_impression) / judgments.count).round(1)
    elsif category.present?
      category_judgements = judgments.by_category(category)
      return if category_judgements.none?
      category_judgements.first.category_score
    else
      judgments.sum(:category_score) + score(:overall_impression)
    end
  end

  def score_display(category=nil)
    raw_score = score(category)
    return "--" if raw_score.nil?
    raw_score&.round(1).to_s.gsub(/(\.)0+$/, '').presence || "--"
  end

  def position
    sort_order
  end

  private

  def set_initial_values
    self.age = age = athlete.age || 0
    self.sort_order = self.class.send(age_group).maximum(:sort_order).to_i + 1
  end
end
