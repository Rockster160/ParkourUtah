class Waiver < ActiveRecord::Base
  # create_table "waivers", force: :cascade do |t|
  #   t.integer  "dependent_id"
  #   t.boolean  "signed"
  #   t.string   "signed_for"
  #   t.string   "signed_by"
  #   t.datetime "created_at",        null: false
  #   t.datetime "updated_at",        null: false
  # end

  belongs_to :dependent
  validate :has_matching_name_as_athlete
  after_create :signed_false

  def exp_date
    (self.created_at + 1.year - 1.day).strftime('%B %-d, %Y')
  end

  def expires_soon?
    (Date.today > (self.exp_date.to_date - 1.week) && self.signed)
  end

  def is_active?
    (Date.today < self.exp_date.to_date && self.signed)
  end

  def has_matching_name_as_athlete
    unless Dependent.find(self.dependent_id).full_name == self.signed_for
      errors.add(:signed_for, "Athlete name must match the one listed.")
    end
  end

  def signed_false
    self.signed = false
  end
end
