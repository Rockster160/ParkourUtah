class CompetitionJudging < ActiveRecord::Migration[5.0]
  def change
    create_table :competition_judgements do |t|
      t.belongs_to :competitor
      t.belongs_to :judge
      t.integer :category
      t.float :category_score
      t.float :overall_impression

      t.timestamps
    end

    add_column :competitors, :age, :integer
    add_column :competitors, :sort_order, :integer

    Competitor.order(:created_at).find_each do |c|
      c.send(:set_initial_values)
      c.save
    end
  end
end
