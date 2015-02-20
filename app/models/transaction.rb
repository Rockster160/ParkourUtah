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

  def item
    LineItem.find(self.item_id)
  end
end
