# == Schema Information
#
# Table name: redemption_keys
#
#  id                         :integer          not null, primary key
#  key                        :string
#  redemption                 :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  redeemed                   :boolean          default(FALSE)
#  line_item_id               :integer
#  can_be_used_multiple_times :boolean          default(FALSE)
#  expires_at                 :datetime
#  max_quantity               :integer
#

class RedemptionKey < ApplicationRecord

  after_create :generate_key
  belongs_to :line_item

  # LineItem.find(x).redemption_keys.create

  scope :expired, -> { where("expires_at < ?", Time.zone.now) }
  # A NULL expires_at means "never expires". `where.not("expires_at < ?")` drops
  # those rows in Postgres — NULL < ts is NULL, and NOT NULL is still NULL — so
  # this scope matched nothing at all, which meant `redeem` below could never
  # find a key and no single-use code was ever marked as used.
  scope :not_expired, -> { where(expires_at: nil).or(where("expires_at >= ?", Time.zone.now)) }
  scope :redeemed, -> { where(redeemed: true) }
  scope :not_redeemed, -> { where.not(redeemed: true) }
  scope :redeemable, -> { not_redeemed.not_expired }

  def self.redeem(key)
    self.not_expired.find_by(key: key)&.tap { |key_to_redeem|
      return true if key_to_redeem.try(:can_be_used_multiple_times?)
      return false if key_to_redeem.redeemed?

      key_to_redeem.update(redeemed: true)
    }
    # No key behind this token — the common case, since most cart items carry a
    # blank one. Nothing to consume, but still truthy: create_charge gates the
    # credit payout on this, and an ordinary purchase should award its credits.
    true
  end

  def expired?
    return false unless expires_at
    self.expires_at < Time.zone.now
  end

  # How many units of the redeemed item a single code may put in the cart, so
  # one code can cover siblings and reach the family/bundle price. nil means
  # unlimited. When max_quantity is unset we keep the historical behavior:
  # multi-use codes were never capped, everything else was locked at one.
  def quantity_limit
    return max_quantity if max_quantity.present?
    return if can_be_used_multiple_times?
    1
  end

  def item; self.line_item; end

  def expiry_date=(date_str)
    begin
      self.expires_at = Time.zone.parse(date_str)
    rescue StandardError
      errors.add(:expires_at, "Must be a valid date.")
    end
  end
  def expiry_date
    self.expires_at&.strftime('%b %d, %Y')
  end

  def generate_key
    return if key.present?

    caps = ('A'..'Z').to_a
    down = ('a'..'z').to_a
    nums = (0..9).to_a

    loop do
      key = 20.times.map {(caps + down + nums).sample}.join('')
      if RedemptionKey.where(key: key).count == 0
        self.update(key: key)
        break
      end
    end
  end

end
