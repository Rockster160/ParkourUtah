class AddDiscountsToCartItems < ActiveRecord::Migration[6.1]
  def change
    add_reference :cart_items, :purchased_plan_item
    add_column :cart_items, :discount_type, :text
    add_column :cart_items, :discount_cost_in_pennies, :integer
  end
end
