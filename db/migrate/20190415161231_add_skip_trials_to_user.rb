class AddSkipTrialsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :skip_trials, :boolean, default: false
  end
end
