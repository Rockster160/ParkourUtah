# == Schema Information
#
# Table name: competitions
#
#  id         :integer          not null, primary key
#  spot_id    :integer
#  name       :string
#  start_time :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Competition < ApplicationRecord
  belongs_to :spot
  has_many :competitors

  scope :current, -> { where("start_time > ?", DateTime.current) }

  def ranked_competitors(age_group, category=nil)
    category_competitors = competitors.approved.send(age_group).joins(:competition_judgements).distinct
    category_competitors.reject { |competitor| competitor.score(category).nil? }.sort_by { |competitor| -competitor.score(category) }
  end

  def competitor_hash
    categories = CompetitionJudgement.categories.keys
    competitors.approved.order(:sort_order).map do |competitor|
      hash = { id: competitor.id }
      categories.each do |category|
        hash[category] = competitor.score_display(category)
      end
      hash[:overall_impression] = competitor.score_display(:overall_impression)
      hash[:total] = competitor.score_display
      hash[:rank] = competitor.rank
      hash
    end
  end
end
