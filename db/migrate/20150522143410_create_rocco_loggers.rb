class CreateRoccoLoggers < ActiveRecord::Migration
  def change
    create_table :rocco_loggers do |t|
      t.text :logs

      t.timestamps null: false
    end
  end
end
