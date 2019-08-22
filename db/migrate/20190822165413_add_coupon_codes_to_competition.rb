class AddCouponCodesToCompetition < ActiveRecord::Migration[5.0]
  def change
    add_column :competitions, :coupon_codes, :text
  end
end
