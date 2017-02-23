class OptionallyDisplayInstructorOnFrontPage < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :should_display_on_front_page, :boolean, default: true
  end
end
