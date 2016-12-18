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

ActiveRecord::Schema.define(version: 20161211181034) do

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

  create_table "athlete_subscriptions", force: :cascade do |t|
    t.integer  "dependent_id"
    t.integer  "usages",          default: 0
    t.datetime "expires_at"
    t.integer  "cost_in_pennies", default: 0
    t.boolean  "auto_renew",      default: true
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "athlete_subscriptions", ["dependent_id"], name: "index_athlete_subscriptions_on_dependent_id", using: :btree

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

  create_table "cart_items", force: :cascade do |t|
    t.integer  "cart_id"
    t.integer  "line_item_id"
    t.integer  "amount",         default: 1
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "redeemed_token", default: ""
    t.string   "order_name"
  end

  add_index "cart_items", ["cart_id"], name: "index_cart_items_on_cart_id", using: :btree

  create_table "carts", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "email"
    t.datetime "purchased_at"
  end

  add_index "carts", ["user_id"], name: "index_carts_on_user_id", using: :btree

  create_table "contact_requests", force: :cascade do |t|
    t.string   "user_agent"
    t.string   "phone"
    t.string   "name"
    t.string   "email"
    t.string   "body"
    t.boolean  "success"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "event_schedules", force: :cascade do |t|
    t.integer  "instructor_id"
    t.integer  "spot_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "hour_of_day"
    t.integer  "minute_of_day"
    t.integer  "day_of_week"
    t.integer  "cost_in_pennies"
    t.string   "title"
    t.text     "description"
    t.string   "full_address"
    t.string   "city"
    t.string   "color"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "event_schedules", ["instructor_id"], name: "index_event_schedules_on_instructor_id", using: :btree
  add_index "event_schedules", ["spot_id"], name: "index_event_schedules_on_spot_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "date"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "event_schedule_id"
    t.datetime "original_date"
    t.boolean  "is_cancelled",      default: false
  end

  create_table "images", force: :cascade do |t|
    t.integer  "spot_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "images", ["spot_id"], name: "index_images_on_spot_id", using: :btree

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
    t.boolean  "is_full_image",        default: false
    t.integer  "redemption_item_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "email_class_reminder",  default: false
    t.boolean "text_class_reminder",   default: false
    t.boolean "email_low_credits",     default: false
    t.boolean "text_low_credits",      default: false
    t.boolean "email_waiver_expiring", default: false
    t.boolean "text_waiver_expiring",  default: false
    t.boolean "sms_receivable"
    t.boolean "text_class_cancelled",  default: false
    t.boolean "email_class_cancelled", default: false
    t.boolean "email_newsletter",      default: true
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "ratings", force: :cascade do |t|
    t.integer  "rated"
    t.integer  "spot_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "ratings", ["spot_id"], name: "index_ratings_on_spot_id", using: :btree

  create_table "redemption_keys", force: :cascade do |t|
    t.string   "key"
    t.string   "redemption"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "redeemed",     default: false
    t.integer  "line_item_id"
  end

  add_index "redemption_keys", ["line_item_id"], name: "index_redemption_keys_on_line_item_id", using: :btree

  create_table "spots", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "lon"
    t.string   "lat"
    t.boolean  "approved",    default: false
    t.integer  "event_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "location"
  end

  add_index "spots", ["event_id"], name: "index_spots_on_event_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_schedule_id"
  end

  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "trial_classes", force: :cascade do |t|
    t.integer  "dependent_id"
    t.boolean  "used",         default: false
    t.datetime "used_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "trial_classes", ["dependent_id"], name: "index_trial_classes_on_dependent_id", using: :btree

  create_table "unlimited_subscriptions", force: :cascade do |t|
    t.integer  "usages",     default: 0
    t.datetime "expires_at"
    t.integer  "user_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "unlimited_subscriptions", ["user_id"], name: "index_unlimited_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                          default: "",    null: false
    t.string   "first_name",                     default: "",    null: false
    t.string   "last_name",                      default: "",    null: false
    t.string   "encrypted_password",             default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                  default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "role",                           default: 0
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
    t.integer  "credits",                        default: 0
    t.string   "phone_number"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "instructor_position"
    t.integer  "payment_multiplier",             default: 3
    t.string   "stats"
    t.string   "title"
    t.string   "nickname"
    t.boolean  "email_subscription",             default: true
    t.string   "stripe_id"
    t.datetime "date_of_birth"
    t.string   "drivers_license_number"
    t.string   "drivers_license_state"
    t.boolean  "registration_complete",          default: false
    t.integer  "registration_step",              default: 2
    t.boolean  "stripe_subscription",            default: false
    t.string   "referrer",                       default: ""
    t.integer  "subscription_cost",              default: 5000
    t.integer  "unassigned_subscriptions_count", default: 0
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "venmos", force: :cascade do |t|
    t.string   "access_token"
    t.string   "refresh_token"
    t.datetime "expires_at"
    t.string   "username"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "waivers", force: :cascade do |t|
    t.integer  "dependent_id"
    t.boolean  "signed"
    t.string   "signed_for"
    t.string   "signed_by"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "waivers", ["dependent_id"], name: "index_waivers_on_dependent_id", using: :btree

  add_foreign_key "athlete_subscriptions", "dependents"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "carts", "users"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "images", "spots"
  add_foreign_key "notifications", "users"
  add_foreign_key "ratings", "spots"
  add_foreign_key "spots", "events"
  add_foreign_key "trial_classes", "dependents"
  add_foreign_key "unlimited_subscriptions", "users"
end
