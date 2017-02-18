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

ActiveRecord::Schema.define(version: 20170218145738) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.integer  "dependent_id"
    t.integer  "user_id"
    t.integer  "event_id"
    t.string   "location"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["dependent_id"], name: "index_attendances_on_dependent_id", using: :btree
    t.index ["event_id"], name: "index_attendances_on_event_id", using: :btree
    t.index ["user_id"], name: "index_attendances_on_user_id", using: :btree
  end

  create_table "aws_loggers", force: :cascade do |t|
    t.text     "orginal_string"
    t.string   "bucket_owner"
    t.string   "bucket"
    t.datetime "time"
    t.string   "remote_ip"
    t.string   "requester"
    t.string   "request_id"
    t.string   "operation"
    t.string   "key"
    t.string   "request_uri"
    t.string   "http_status"
    t.string   "error_code"
    t.bigint   "bytes_sent"
    t.bigint   "object_size"
    t.bigint   "total_time"
    t.bigint   "turn_around_time"
    t.string   "referrer"
    t.string   "user_agent"
    t.string   "version_id"
    t.boolean  "set_all_without_errors"
  end

  create_table "carts", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_carts_on_user_id", using: :btree
  end

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
    t.index ["user_id"], name: "index_dependents_on_user_id", using: :btree
  end

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

  create_table "messages", force: :cascade do |t|
    t.integer  "sent_from_id"
    t.boolean  "sent_to_user"
    t.string   "stripped_phone_number"
    t.text     "body"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "sent_to_id"
    t.datetime "read_at"
    t.integer  "message_type"
    t.index ["sent_from_id"], name: "index_messages_on_sent_from_id", using: :btree
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "cart_id"
    t.integer  "item_id"
    t.integer  "amount",     default: 1
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["cart_id"], name: "index_transactions_on_cart_id", using: :btree
  end

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
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
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
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "waivers", force: :cascade do |t|
    t.integer  "dependent_id"
    t.boolean  "signed"
    t.string   "signed_for"
    t.string   "signed_by"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["dependent_id"], name: "index_waivers_on_dependent_id", using: :btree
  end

  add_foreign_key "carts", "users"
  add_foreign_key "transactions", "carts"
end
