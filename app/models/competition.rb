# == Schema Information
#
# Table name: competitions
#
#  id             :integer          not null, primary key
#  spot_id        :integer
#  name           :string
#  start_time     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  slug           :string
#  description    :text
#  option_costs   :text
#  sponsor_images :text
#  coupon_codes   :text
#

class Competition < ApplicationRecord
  serialize :option_costs,   JSONWrapper
  serialize :sponsor_images, JSONWrapper
  serialize :coupon_codes,   JSONWrapper

  belongs_to :spot, optional: true
  has_many :competitors

  scope :current, -> { where("start_time > ?", DateTime.current) }

  def late_registration?(from_time=Time.current)
    from_time > start_time.beginning_of_week
  end

  def options
    @options ||= option_costs.deep_symbolize_keys
  end

  def registration_time
    late_registration? ? :late : :early
  end

  def select_options(age_group)
    (options.dig(age_group, registration_time) || []).map do |comp_name, price|
      ["#{comp_name} ($#{price})", comp_name]
    end
  end

  def age_groups
    options.keys
  end

  def cost_range
    options = option_costs.deep_symbolize_keys
    return "$#{options[:all]}" if options[:all].present?

    min = nil
    max = nil
    options.each do |age_group, registration_time|
      registration_time.each do |time, comps|
        comps.each do |name, price|
          min = price if min.nil? || price < min
          max = price if max.nil? || price > max
        end
      end
    end

    [min, max].compact.map { |price| "$#{price}" }.join("-")
  end

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
