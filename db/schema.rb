# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150316023238) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.integer  "dependent_id"
    t.integer  "instructor_id"
    t.integer  "event_id"
    t.string   "location"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "type_of_charge"
    t.boolean  "sent",           default: false
  end

  add_index "attendances", ["dependent_id"], name: "index_attendances_on_dependent_id", using: :btree
  add_index "attendances", ["event_id"], name: "index_attendances_on_event_id", using: :btree
  add_index "attendances", ["instructor_id"], name: "index_attendances_on_instructor_id", using: :btree

  create_table "carts", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "carts", ["user_id"], name: "index_carts_on_user_id", using: :btree

  create_table "dependents", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "full_name"
    t.string   "emergency_contact"
    t.integer  "athlete_id"
    t.integer  "athlete_pin"
    t.string   "athlete_photo_file_name"
    t.string   "athlete_photo_content_type"
    t.integer  "athlete_photo_file_size"
    t.datetime "athlete_photo_updated_at"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "dependents", ["user_id"], name: "index_dependents_on_user_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "date"
    t.integer  "token"
    t.string   "title"
    t.string   "host"
    t.float    "cost"
    t.text     "description"
    t.string   "city"
    t.string   "address"
    t.string   "location_instructions"
    t.string   "class_name"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "line_items", force: :cascade do |t|
    t.string   "display_file_name"
    t.string   "display_content_type"
    t.integer  "display_file_size"
    t.datetime "display_updated_at"
    t.text     "description"
    t.integer  "cost_in_pennies"
    t.string   "title"
    t.string   "category"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "size"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "cart_id"
    t.integer  "item_id"
    t.integer  "amount",     default: 1
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "transactions", ["cart_id"], name: "index_transactions_on_cart_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "first_name",             default: "", null: false
    t.string   "last_name",              default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "role",                   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "avatar_2_file_name"
    t.string   "avatar_2_content_type"
    t.integer  "avatar_2_file_size"
    t.datetime "avatar_2_updated_at"
    t.text     "bio"
    t.integer  "auth_net_id"
    t.integer  "payment_id"
    t.integer  "credits",                default: 0
    t.string   "phone_number"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "instructor_position"
    t.integer  "payment_multiplier",     default: 3
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "waivers", force: :cascade do |t|
    t.integer  "dependent_id"
    t.boolean  "signed"
    t.string   "signed_for"
    t.string   "signed_by"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "waivers", ["dependent_id"], name: "index_waivers_on_dependent_id", using: :btree

  add_foreign_key "carts", "users"
  add_foreign_key "transactions", "carts"
end
