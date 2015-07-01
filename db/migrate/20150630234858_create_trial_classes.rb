class CreateTrialClasses < ActiveRecord::Migration
  def change
    create_table :trial_classes do |t|
      t.belongs_to :dependent, index: true
      t.boolean :used, default: false
      t.timestamp :used_at

      t.timestamps null: false
    end
    add_foreign_key :trial_classes, :dependents
  end
end
