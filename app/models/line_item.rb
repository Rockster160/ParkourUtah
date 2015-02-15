class LineItem < ActiveRecord::Base
  # create_table "line_items", force: :cascade do |t|
  #   t.string   "display_file_name"
  #   t.string   "display_content_type"
  #   t.integer  "display_file_size"
  #   t.datetime "display_updated_at"
  #   t.text     "description"
  #   t.float    "cost"
  #   t.string   "title"
  #   t.datetime "created_at",           null: false
  #   t.datetime "updated_at",           null: false
  # end

  has_attached_file :display,
    :styles => { :medium => "300x300>", :thumb => "100x100#" },
    :default_url => "/images/missing.png",
    :convert_options => { :all => '-background white -flatten +matte' }
  validates_attachment_content_type :display, :content_type => /\Aimage\/.*\Z/
end
