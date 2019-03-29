class AddCouponCodeToCompetitor < ActiveRecord::Migration[5.0]
  def change
    add_column :competitors, :coupon_code, :string
  end
end
