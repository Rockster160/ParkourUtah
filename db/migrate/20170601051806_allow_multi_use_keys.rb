class AllowMultiUseKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :redemption_keys, :can_be_used_multiple_times, :boolean, default: false
  end
end
