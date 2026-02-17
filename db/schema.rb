# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_01_01_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", precision: nil, null: false
    t.string "line1"
    t.string "line2"
    t.string "state"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.string "zip"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "announcements", id: :serial, force: :cascade do |t|
    t.integer "admin_id"
    t.text "body"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "delivered_at", precision: nil
    t.datetime "expires_at", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.index ["admin_id"], name: "index_announcements_on_admin_id"
  end

  create_table "athletes", id: :serial, force: :cascade do |t|
    t.string "athlete_photo_content_type"
    t.string "athlete_photo_file_name"
    t.integer "athlete_photo_file_size"
    t.datetime "athlete_photo_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "date_of_birth"
    t.string "emergency_contact"
    t.integer "fast_pass_id"
    t.integer "fast_pass_pin"
    t.string "first_name"
    t.string "full_name"
    t.string "last_name"
    t.string "middle_name"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.boolean "verified", default: false
    t.index ["user_id"], name: "index_athletes_on_user_id"
  end

  create_table "attendances", id: :serial, force: :cascade do |t|
    t.integer "athlete_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "event_id"
    t.integer "instructor_id"
    t.string "location"
    t.bigint "purchased_plan_item_id"
    t.boolean "sent", default: false
    t.string "type_of_charge"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["athlete_id"], name: "index_attendances_on_athlete_id"
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["instructor_id"], name: "index_attendances_on_instructor_id"
    t.index ["purchased_plan_item_id"], name: "index_attendances_on_purchased_plan_item_id"
  end

  create_table "aws_loggers", id: :serial, force: :cascade do |t|
    t.string "bucket"
    t.string "bucket_owner"
    t.bigint "bytes_sent"
    t.string "error_code"
    t.string "http_status"
    t.string "key"
    t.bigint "object_size"
    t.string "operation"
    t.text "orginal_string"
    t.string "referrer"
    t.string "remote_ip"
    t.string "request_id"
    t.string "request_uri"
    t.string "requester"
    t.boolean "set_all_without_errors"
    t.datetime "time", precision: nil
    t.bigint "total_time"
    t.bigint "turn_around_time"
    t.string "user_agent"
    t.string "version_id"
  end

  create_table "cart_items", id: :serial, force: :cascade do |t|
    t.integer "amount", default: 1
    t.integer "cart_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "discount_cost_in_pennies"
    t.text "discount_type"
    t.integer "line_item_id"
    t.string "order_name"
    t.bigint "purchased_plan_item_id"
    t.string "redeemed_token", default: ""
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["purchased_plan_item_id"], name: "index_cart_items_on_purchased_plan_item_id"
  end

  create_table "carts", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.datetime "purchased_at", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "chat_room_users", id: :serial, force: :cascade do |t|
    t.boolean "banned", default: false
    t.integer "chat_room_id"
    t.datetime "created_at", precision: nil, null: false
    t.boolean "has_unread_messages", default: true
    t.boolean "muted", default: false
    t.boolean "notify_via_css", default: false
    t.boolean "notify_via_email", default: true
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["chat_room_id"], name: "index_chat_room_users_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_room_users_on_user_id"
  end

  create_table "chat_rooms", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_message_received_at", precision: nil
    t.integer "message_type"
    t.string "name"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "visibility_level"
  end

  create_table "competition_judgements", id: :serial, force: :cascade do |t|
    t.integer "category"
    t.float "category_score"
    t.integer "competitor_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "judge_id"
    t.float "overall_impression"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["competitor_id"], name: "index_competition_judgements_on_competitor_id"
    t.index ["judge_id"], name: "index_competition_judgements_on_judge_id"
  end

  create_table "competitions", id: :serial, force: :cascade do |t|
    t.text "coupon_codes"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "name"
    t.text "option_costs"
    t.string "slug"
    t.text "sponsor_images"
    t.integer "spot_id"
    t.datetime "start_time", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.index ["spot_id"], name: "index_competitions_on_spot_id"
  end

  create_table "competitors", id: :serial, force: :cascade do |t|
    t.integer "age"
    t.datetime "approved_at", precision: nil
    t.integer "athlete_id"
    t.string "bio"
    t.integer "competition_id"
    t.string "coupon_code"
    t.datetime "created_at", precision: nil, null: false
    t.string "instagram_handle"
    t.string "referred_by"
    t.string "selected_comp"
    t.string "shirt_size"
    t.text "signup_data"
    t.string "song"
    t.integer "sort_order"
    t.string "stripe_charge_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "years_training"
    t.index ["athlete_id"], name: "index_competitors_on_athlete_id"
    t.index ["competition_id"], name: "index_competitors_on_competition_id"
  end

  create_table "contact_requests", id: :serial, force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.boolean "success"
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_agent"
  end

  create_table "emergency_contacts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "number"
    t.integer "user_id"
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id"
  end

  create_table "event_schedules", id: :serial, force: :cascade do |t|
    t.boolean "accepts_trial_classes", default: true
    t.boolean "accepts_unlimited_classes", default: true
    t.string "city"
    t.string "color"
    t.integer "cost_in_pennies"
    t.datetime "created_at", precision: nil
    t.integer "day_of_week"
    t.text "description"
    t.datetime "end_date", precision: nil
    t.string "full_address"
    t.integer "hour_of_day"
    t.integer "instructor_id"
    t.integer "max_payment_per_session"
    t.integer "min_payment_per_session"
    t.integer "minute_of_day"
    t.integer "payment_per_student"
    t.integer "spot_id"
    t.datetime "start_date", precision: nil
    t.jsonb "tags"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.index ["instructor_id"], name: "index_event_schedules_on_instructor_id"
    t.index ["spot_id"], name: "index_event_schedules_on_spot_id"
  end

  create_table "event_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "event_schedule_id"
    t.integer "user_id"
    t.index ["user_id"], name: "index_event_subscriptions_on_user_id"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "date", precision: nil
    t.integer "event_schedule_id"
    t.boolean "is_cancelled", default: false
    t.datetime "original_date", precision: nil
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "spot_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["spot_id"], name: "index_images_on_spot_id"
  end

  create_table "line_items", id: :serial, force: :cascade do |t|
    t.integer "bundle_amount"
    t.integer "bundle_cost_in_pennies"
    t.string "category"
    t.string "color"
    t.integer "cost_in_pennies"
    t.datetime "created_at", precision: nil, null: false
    t.integer "credits", default: 0
    t.text "description"
    t.string "display_content_type"
    t.string "display_file_name"
    t.integer "display_file_size"
    t.datetime "display_updated_at", precision: nil
    t.boolean "hidden"
    t.string "instructor_ids"
    t.boolean "is_full_image", default: false
    t.boolean "is_subscription", default: false
    t.integer "item_order"
    t.string "location_ids"
    t.bigint "plan_item_id"
    t.integer "redemption_item_id"
    t.boolean "show_text_as_image", default: true
    t.string "size"
    t.jsonb "tags"
    t.boolean "taxable", default: true
    t.string "time_range_end"
    t.string "time_range_start"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["plan_item_id"], name: "index_line_items_on_plan_item_id"
  end

  create_table "log_trackers", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "http_method"
    t.string "ip_address"
    t.string "params"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.string "user_agent"
    t.integer "user_id"
    t.index ["user_id"], name: "index_log_trackers_on_user_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.text "body"
    t.integer "chat_room_id"
    t.datetime "created_at", precision: nil, null: false
    t.boolean "error", default: false
    t.string "error_message"
    t.integer "message_type"
    t.datetime "read_at", precision: nil
    t.integer "sent_from_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["sent_from_id"], name: "index_messages_on_sent_from_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.boolean "email_class_cancelled", default: false
    t.boolean "email_class_reminder", default: false
    t.boolean "email_low_credits", default: false
    t.boolean "email_newsletter", default: true
    t.boolean "email_waiver_expiring", default: false
    t.boolean "sms_receivable"
    t.boolean "text_class_cancelled", default: false
    t.boolean "text_class_reminder", default: false
    t.boolean "text_low_credits", default: false
    t.boolean "text_waiver_expiring", default: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "plan_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "discount_items"
    t.jsonb "free_items"
    t.text "name"
    t.datetime "updated_at", null: false
  end

  create_table "purchased_plan_items", force: :cascade do |t|
    t.bigint "athlete_id"
    t.boolean "auto_renew", default: true
    t.text "card_declined"
    t.bigint "cart_id"
    t.integer "cost_in_pennies"
    t.datetime "created_at", null: false
    t.jsonb "discount_items"
    t.datetime "expires_at", precision: nil
    t.jsonb "free_items"
    t.bigint "plan_item_id"
    t.text "stripe_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["athlete_id"], name: "index_purchased_plan_items_on_athlete_id"
    t.index ["cart_id"], name: "index_purchased_plan_items_on_cart_id"
    t.index ["plan_item_id"], name: "index_purchased_plan_items_on_plan_item_id"
    t.index ["user_id"], name: "index_purchased_plan_items_on_user_id"
  end

  create_table "ratings", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "rated"
    t.integer "spot_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["spot_id"], name: "index_ratings_on_spot_id"
  end

  create_table "recurring_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "athlete_id"
    t.boolean "auto_renew", default: true
    t.boolean "card_declined"
    t.integer "cost_in_pennies", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "expires_at", precision: nil
    t.string "stripe_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "usages", default: 0
    t.integer "user_id"
    t.index ["athlete_id"], name: "index_recurring_subscriptions_on_athlete_id"
  end

  create_table "redemption_keys", id: :serial, force: :cascade do |t|
    t.boolean "can_be_used_multiple_times", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "expires_at", precision: nil
    t.string "key"
    t.integer "line_item_id"
    t.boolean "redeemed", default: false
    t.string "redemption"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["line_item_id"], name: "index_redemption_keys_on_line_item_id"
  end

  create_table "spots", id: :serial, force: :cascade do |t|
    t.boolean "approved", default: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "event_id"
    t.string "lat"
    t.string "location"
    t.string "lon"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_spots_on_event_id"
  end

  create_table "trial_classes", id: :serial, force: :cascade do |t|
    t.integer "athlete_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "used", default: false
    t.datetime "used_at", precision: nil
    t.index ["athlete_id"], name: "index_trial_classes_on_athlete_id"
  end

  create_table "unlimited_subscriptions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "expires_at", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.integer "usages", default: 0
    t.integer "user_id"
    t.index ["user_id"], name: "index_unlimited_subscriptions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "avatar_2_content_type"
    t.string "avatar_2_file_name"
    t.integer "avatar_2_file_size"
    t.datetime "avatar_2_updated_at", precision: nil
    t.string "avatar_content_type"
    t.string "avatar_file_name"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.text "bio"
    t.boolean "can_receive_emails", default: true
    t.boolean "can_receive_sms", default: true
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.integer "credits", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.datetime "date_of_birth", precision: nil
    t.string "drivers_license_number"
    t.string "drivers_license_state"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", default: "", null: false
    t.string "full_name"
    t.integer "instructor_position"
    t.string "last_name", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.string "nickname"
    t.string "phone_number"
    t.string "referrer", default: ""
    t.boolean "registration_complete", default: false
    t.integer "registration_step", default: 2
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "role", default: 0
    t.boolean "should_display_on_front_page", default: true
    t.integer "sign_in_count", default: 0, null: false
    t.boolean "skip_trials", default: false
    t.string "stats"
    t.string "stripe_id"
    t.boolean "stripe_subscription", default: false
    t.integer "subscription_cost", default: 5000
    t.string "title"
    t.integer "unassigned_subscriptions_count", default: 0
    t.datetime "updated_at", precision: nil
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "waivers", id: :serial, force: :cascade do |t|
    t.integer "athlete_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "expiry_date", precision: nil
    t.boolean "signed"
    t.string "signed_by"
    t.string "signed_for"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["athlete_id"], name: "index_waivers_on_athlete_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
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
