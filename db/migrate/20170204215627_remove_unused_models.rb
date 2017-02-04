class RemoveUnusedModels < ActiveRecord::Migration[5.0]
  def change
    drop_table :automators
    drop_table :venmos
  end
end
