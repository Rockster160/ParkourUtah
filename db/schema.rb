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

ActiveRecord::Schema.define(version: 20180530005449) do

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
    t.index ["user_id"], name: "index_addresses_on_user_id", using: :btree
  end

  create_table "announcements", force: :cascade do |t|
    t.integer  "admin_id"
    t.datetime "expires_at"
    t.text     "body"
    t.datetime "delivered_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["admin_id"], name: "index_announcements_on_admin_id", using: :btree
  end

  create_table "athletes", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "full_name"
    t.string   "emergency_contact"
    t.integer  "fast_pass_id"
    t.integer  "fast_pass_pin"
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
    t.index ["user_id"], name: "index_athletes_on_user_id", using: :btree
  end

  create_table "attendances", force: :cascade do |t|
    t.integer  "athlete_id"
    t.integer  "instructor_id"
    t.integer  "event_id"
    t.string   "location"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "type_of_charge"
    t.boolean  "sent",           default: false
    t.index ["athlete_id"], name: "index_attendances_on_athlete_id", using: :btree
    t.index ["event_id"], name: "index_attendances_on_event_id", using: :btree
    t.index ["instructor_id"], name: "index_attendances_on_instructor_id", using: :btree
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

  create_table "cart_items", force: :cascade do |t|
    t.integer  "cart_id"
    t.integer  "line_item_id"
    t.integer  "amount",         default: 1
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "redeemed_token", default: ""
    t.string   "order_name"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id", using: :btree
  end

  create_table "carts", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "email"
    t.datetime "purchased_at"
    t.index ["user_id"], name: "index_carts_on_user_id", using: :btree
  end

  create_table "chat_room_users", force: :cascade do |t|
    t.integer  "chat_room_id"
    t.integer  "user_id"
    t.boolean  "has_unread_messages", default: true
    t.boolean  "notify_via_email",    default: true
    t.boolean  "notify_via_css",      default: false
    t.boolean  "muted",               default: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "banned",              default: false
    t.index ["chat_room_id"], name: "index_chat_room_users_on_chat_room_id", using: :btree
    t.index ["user_id"], name: "index_chat_room_users_on_user_id", using: :btree
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.string   "name"
    t.integer  "visibility_level"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "message_type"
    t.datetime "last_message_received_at"
  end

  create_table "competitions", force: :cascade do |t|
    t.integer  "spot_id"
    t.string   "name"
    t.datetime "start_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spot_id"], name: "index_competitions_on_spot_id", using: :btree
  end

  create_table "competitors", force: :cascade do |t|
    t.integer  "athlete_id"
    t.integer  "competition_id"
    t.string   "years_training"
    t.string   "instagram_handle"
    t.string   "song"
    t.string   "bio"
    t.string   "stripe_charge_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["athlete_id"], name: "index_competitors_on_athlete_id", using: :btree
    t.index ["competition_id"], name: "index_competitors_on_competition_id", using: :btree
  end

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

  create_table "emergency_contacts", force: :cascade do |t|
    t.integer "user_id"
    t.string  "number"
    t.string  "name"
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id", using: :btree
  end

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
    t.integer  "payment_per_student"
    t.integer  "min_payment_per_session"
    t.integer  "max_payment_per_session"
    t.boolean  "accepts_unlimited_classes", default: true
    t.boolean  "accepts_trial_classes",     default: true
    t.index ["instructor_id"], name: "index_event_schedules_on_instructor_id", using: :btree
    t.index ["spot_id"], name: "index_event_schedules_on_spot_id", using: :btree
  end

  create_table "event_subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_schedule_id"
    t.index ["user_id"], name: "index_event_subscriptions_on_user_id", using: :btree
  end

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
    t.index ["spot_id"], name: "index_images_on_spot_id", using: :btree
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
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "size"
    t.boolean  "hidden"
    t.integer  "item_order"
    t.integer  "credits",                default: 0
    t.boolean  "is_subscription",        default: false
    t.boolean  "taxable",                default: true
    t.string   "color"
    t.boolean  "is_full_image",          default: false
    t.integer  "redemption_item_id"
    t.boolean  "show_text_as_image",     default: true
    t.string   "instructor_ids"
    t.string   "location_ids"
    t.string   "time_range_start"
    t.string   "time_range_end"
    t.integer  "bundle_amount"
    t.integer  "bundle_cost_in_pennies"
  end

  create_table "log_trackers", force: :cascade do |t|
    t.string   "user_agent"
    t.string   "ip_address"
    t.string   "http_method"
    t.string   "url"
    t.string   "params"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["user_id"], name: "index_log_trackers_on_user_id", using: :btree
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "sent_from_id"
    t.text     "body"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.datetime "read_at"
    t.integer  "message_type"
    t.boolean  "error",         default: false
    t.string   "error_message"
    t.integer  "chat_room_id"
    t.index ["sent_from_id"], name: "index_messages_on_sent_from_id", using: :btree
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
    t.index ["user_id"], name: "index_notifications_on_user_id", using: :btree
  end

  create_table "ratings", force: :cascade do |t|
    t.integer  "rated"
    t.integer  "spot_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spot_id"], name: "index_ratings_on_spot_id", using: :btree
  end

  create_table "recurring_subscriptions", force: :cascade do |t|
    t.integer  "athlete_id"
    t.integer  "usages",          default: 0
    t.datetime "expires_at"
    t.integer  "cost_in_pennies", default: 0
    t.boolean  "auto_renew",      default: true
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "stripe_id"
    t.integer  "user_id"
    t.boolean  "card_declined"
    t.index ["athlete_id"], name: "index_recurring_subscriptions_on_athlete_id", using: :btree
  end

  create_table "redemption_keys", force: :cascade do |t|
    t.string   "key"
    t.string   "redemption"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "redeemed",                   default: false
    t.integer  "line_item_id"
    t.boolean  "can_be_used_multiple_times", default: false
    t.datetime "expires_at"
    t.index ["line_item_id"], name: "index_redemption_keys_on_line_item_id", using: :btree
  end

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
    t.index ["event_id"], name: "index_spots_on_event_id", using: :btree
  end

  create_table "trial_classes", force: :cascade do |t|
    t.integer  "athlete_id"
    t.boolean  "used",       default: false
    t.datetime "used_at"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["athlete_id"], name: "index_trial_classes_on_athlete_id", using: :btree
  end

  create_table "unlimited_subscriptions", force: :cascade do |t|
    t.integer  "usages",     default: 0
    t.datetime "expires_at"
    t.integer  "user_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["user_id"], name: "index_unlimited_subscriptions_on_user_id", using: :btree
  end

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
    t.string   "stats"
    t.string   "title"
    t.string   "nickname"
    t.boolean  "can_receive_emails",             default: true
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
    t.boolean  "should_display_on_front_page",   default: true
    t.boolean  "can_receive_sms",                default: true
    t.string   "full_name"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "waivers", force: :cascade do |t|
    t.integer  "athlete_id"
    t.boolean  "signed"
    t.string   "signed_for"
    t.string   "signed_by"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "expiry_date"
    t.index ["athlete_id"], name: "index_waivers_on_athlete_id", using: :btree
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "carts", "users"
  add_foreign_key "chat_room_users", "chat_rooms"
  add_foreign_key "chat_room_users", "users"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "images", "spots"
  add_foreign_key "notifications", "users"
  add_foreign_key "ratings", "spots"
  add_foreign_key "recurring_subscriptions", "athletes"
  add_foreign_key "spots", "events"
  add_foreign_key "trial_classes", "athletes"
  add_foreign_key "unlimited_subscriptions", "users"
end
