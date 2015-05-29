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

ActiveRecord::Schema.define(version: 20150528175432) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "line1"
    t.string   "line2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "addresses", ["user_id"], name: "index_addresses_on_user_id", using: :btree

  create_table "attendances", force: :cascade do |t|
    t.integer  "dependent_id"
    t.integer  "user_id"
    t.integer  "event_id"
    t.string   "location"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "type_of_charge"
    t.boolean  "sent",           default: false
  end

  add_index "attendances", ["dependent_id"], name: "index_attendances_on_dependent_id", using: :btree
  add_index "attendances", ["event_id"], name: "index_attendances_on_event_id", using: :btree
  add_index "attendances", ["user_id"], name: "index_attendances_on_user_id", using: :btree

  create_table "automators", force: :cascade do |t|
    t.boolean  "open",       default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

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
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "date_of_birth"
    t.boolean  "verified",                   default: false
  end

  add_index "dependents", ["user_id"], name: "index_dependents_on_user_id", using: :btree

  create_table "emergency_contacts", force: :cascade do |t|
    t.integer "user_id"
    t.string  "number"
    t.string  "name"
  end

  add_index "emergency_contacts", ["user_id"], name: "index_emergency_contacts_on_user_id", using: :btree

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
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "zip"
    t.string   "state",                 default: "Utah"
    t.integer  "color"
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
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "size"
    t.boolean  "hidden"
    t.integer  "item_order"
    t.integer  "credits",              default: 0
    t.boolean  "is_subscription",      default: false
    t.boolean  "taxable",              default: true
    t.string   "color"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "email_class_reminder",  default: false
    t.boolean "text_class_reminder",   default: false
    t.boolean "email_low_credits",     default: false
    t.boolean "text_low_credits",      default: false
    t.boolean "email_waiver_expiring", default: false
    t.boolean "text_waiver_expiring",  default: false
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "redemption_keys", force: :cascade do |t|
    t.string   "key"
    t.string   "redemption"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "redeemed",     default: false
    t.integer  "line_item_id"
  end

  add_index "redemption_keys", ["line_item_id"], name: "index_redemption_keys_on_line_item_id", using: :btree

  create_table "rocco_loggers", force: :cascade do |t|
    t.text     "logs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_id"
    t.integer "token"
  end

  add_index "subscriptions", ["event_id"], name: "index_subscriptions_on_event_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "transactions", force: :cascade do |t|
    t.integer  "cart_id"
    t.integer  "item_id"
    t.integer  "amount",         default: 1
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "redeemed_token"
    t.string   "order_name"
  end

  add_index "transactions", ["cart_id"], name: "index_transactions_on_cart_id", using: :btree

  create_table "unlimited_subscriptions", force: :cascade do |t|
    t.integer  "usages",     default: 0
    t.datetime "expires_at"
    t.integer  "user_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "unlimited_subscriptions", ["user_id"], name: "index_unlimited_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "first_name",             default: "",    null: false
    t.string   "last_name",              default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
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
    t.integer  "credits",                default: 0
    t.string   "phone_number"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "instructor_position"
    t.integer  "payment_multiplier",     default: 3
    t.string   "stats"
    t.string   "title"
    t.string   "nickname"
    t.boolean  "email_subscription",     default: true
    t.string   "stripe_id"
    t.datetime "date_of_birth"
    t.string   "drivers_license_number"
    t.string   "drivers_license_state"
    t.boolean  "registration_complete",  default: false
    t.integer  "registration_step",      default: 2
    t.boolean  "stripe_subscription",    default: false
    t.string   "referrer",               default: ""
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
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "transactions", "carts"
  add_foreign_key "unlimited_subscriptions", "users"
end
