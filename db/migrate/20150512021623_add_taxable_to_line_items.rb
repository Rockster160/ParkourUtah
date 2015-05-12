class AddTaxableToLineItems < ActiveRecord::Migration
  def change
    add_column :line_items, :taxable, :boolean, default: true
  end
end
