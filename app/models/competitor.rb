# == Schema Information
#
# Table name: competitors
#
#  id               :integer          not null, primary key
#  age              :integer
#  approved_at      :datetime
#  bio              :string
#  coupon_code      :string
#  instagram_handle :string
#  referred_by      :string
#  selected_comp    :string
#  shirt_size       :string
#  signup_data      :text
#  song             :string
#  sort_order       :integer
#  years_training   :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  athlete_id       :integer
#  competition_id   :integer
#  stripe_charge_id :string
#

class Competitor < ApplicationRecord
  serialize :signup_data, JSONWrapper

  belongs_to :athlete
  belongs_to :competition
  has_many :competition_judgements

  scope :youth, -> { where("age < 14") }
  scope :adult, -> { where("age >= 14") }
  scope :approved, -> { where.not(approved_at: nil) }

  delegate :full_name, to: :athlete
  delegate :age,       to: :athlete
  delegate :youth?,    to: :athlete
  delegate :adult?,    to: :athlete
  delegate :age_group, to: :athlete

  before_save -> { set_initial_values }

  def cost
    costs = competition.options
    return costs[:all] if costs[:all].present? && !costs[:all].is_a?(Hash)

    registration_period = competition.late_registration?(created_at || Time.current) ? :late : :early

    group = (costs.key?(age_group) ? costs[age_group] : costs[:all]) || {}
    period = group.key?(registration_period) ? group[registration_period] : group[:all]

    period[selected_comp.to_s.to_sym]
  end

  def discounted_cost
    return cost.to_f unless coupon_code.present?
    coupon = competition.coupon_codes.find { |k, _v| k.to_s.downcase == coupon_code.downcase }&.last
    return cost.to_f unless coupon.present?

    eval(coupon.gsub("cost", cost.to_s)).to_f
  rescue StandardError
    cost.to_f
  end

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
    self.sort_order ||= self.class.send(age_group).maximum(:sort_order).to_i + 1
  end
end

# Competitor.find_each {|c| c.send(:set_initial_values); c.save}
# Competitor.order(:created_at).youth.each.with_index {|c, idx| c.update(sort_order: idx + 1)}
# Competitor.order(:created_at).adult.each.with_index {|c, idx| c.update(sort_order: idx + 1)}
