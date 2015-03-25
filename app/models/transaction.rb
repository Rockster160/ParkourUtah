class Transaction < ActiveRecord::Base
  # create_table :transactions do |t|
  #   t.belongs_to :cart, index: true
  #   t.integer :item_id
  #   t.integer :amount, default: 1
  #
  #   t.timestamps null: false
  # end
  # add_foreign_key :transactions, :carts

  belongs_to :cart
  belongs_to :user

  before_save :verify_amount_is_not_nil

  def item
    LineItem.find(self.item_id)
  end

  def verify_amount_is_not_nil
    self.amount ||= 0
    self.redeemed_token ||= ""
  end
end
