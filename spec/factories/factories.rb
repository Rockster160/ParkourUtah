FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    first_name { "Test" }
    last_name { "User" }
    role { 0 }
    credits { 100 }
    phone_number { "8015551234" }
    registration_step { 3 }
    confirmed_at { Time.current }

    trait :instructor do
      role { 1 }
      sequence(:instructor_position) { |n| n }
    end

    trait :mod do
      role { 2 }
    end

    trait :admin do
      role { 3 }
    end

    trait :with_address do
      after(:create) do |user|
        create(:address, user: user)
      end
    end

    trait :with_athlete do
      after(:create) do |user|
        create(:athlete, user: user)
      end
    end
  end

  factory :address do
    user
    line1 { "123 Main St" }
    line2 { "" }
    city { "Salt Lake City" }
    state { "UT" }
    zip { "84101" }
  end

  factory :notifications do
    user
    email_newsletter { true }
    email_class_reminder { true }
    email_low_credits { true }
    email_waiver_expiring { true }
    email_class_cancelled { true }
    text_class_reminder { false }
    text_low_credits { false }
    text_waiver_expiring { false }
    text_class_cancelled { false }
  end

  factory :athlete do
    user
    sequence(:full_name) { |n| "Athlete #{n}" }
    date_of_birth { "01/15/2000" }
    verified { false }
    sequence(:fast_pass_id) { |n| 1000 + n }
    fast_pass_pin { 1234 }
  end

  factory :event_schedule do
    association :instructor, factory: [:user, :instructor]
    title { "Parkour Basics" }
    city { "Salt Lake City" }
    color { "#FF5733" }
    cost_in_pennies { 1000 }
    start_date { 1.month.ago }
    day_of_week { Date.current.wday }
    hour_of_day { 17 }
    minute_of_day { 0 }
    full_address { "123 Gym St, Salt Lake City, UT" }
    payment_per_student { 4 }
    min_payment_per_session { 15 }
    accepts_trial_classes { true }
    accepts_unlimited_classes { true }

    # tags= setter expects a string; bypass it for the factory
    after(:build) do |es|
      es.write_attribute(:tags, ["classes"]) unless es.tags.present?
    end
  end

  factory :event do
    event_schedule
    date { Time.zone.now }

    trait :cancelled do
      is_cancelled { true }
    end
  end

  factory :attendance do
    athlete
    association :instructor, factory: [:user, :instructor]
    event
    type_of_charge { "Credits" }

    trait :skip_validations do
      transient do
        skip_validation { true }
      end
      after(:build) { |a| a.skip_validations = true }
    end
  end

  factory :line_item do
    title { "Class Credits" }
    cost_in_pennies { 2000 }
    category { "Class" }
    credits { 10 }
    taxable { true }
    sequence(:item_order) { |n| n }

    trait :clothing do
      title { "T-Shirt" }
      category { "Clothing" }
      credits { 0 }
      cost_in_pennies { 2500 }
    end

    trait :gift_card do
      title { "Gift Card" }
      category { "Gift Card" }
      credits { 0 }
      cost_in_pennies { 2500 }
      taxable { false }
    end

    trait :subscription do
      title { "Monthly Subscription" }
      category { "Class" }
      is_subscription { true }
      cost_in_pennies { 5500 }
    end

    trait :with_plan do
      transient do
        plan { nil }
      end
      after(:create) do |li, evaluator|
        if evaluator.plan
          li.update_column(:plan_item_id, evaluator.plan.id)
        end
      end
    end

    trait :hidden do
      hidden { true }
    end
  end

  factory :cart do
    user

    trait :purchased do
      purchased_at { Time.current }
    end
  end

  factory :cart_item do
    cart
    line_item
    amount { 1 }
    order_name { "Test Item" }
  end

  factory :waiver do
    athlete
    signed { false }
    signed_for { nil }
    expiry_date { 1.year.from_now - 1.day }

    after(:build) do |waiver|
      waiver.signed_for ||= waiver.athlete.full_name
    end

    trait :signed do
      signed { true }
    end

    trait :expired do
      expiry_date { 1.day.ago }
    end

    trait :expiring_soon do
      signed { true }
      expiry_date { 5.days.from_now }
    end
  end

  factory :trial_class do
    athlete
    used { false }

    trait :used do
      used { true }
      used_at { Time.current }
    end
  end

  factory :recurring_subscription do
    user
    athlete { nil }
    cost_in_pennies { 5500 }
    auto_renew { true }
    expires_at { nil }

    trait :active do
      association :athlete
      expires_at { 1.month.from_now }
    end

    trait :expired do
      association :athlete
      expires_at { 2.days.ago }
    end
  end

  factory :purchased_plan_item do
    user
    plan_item
    cost_in_pennies { 7500 }
    auto_renew { true }

    # Bypass PlanItem setters by writing jsonb directly
    after(:build) do |ppi|
      ppi.write_attribute(:free_items, [{ "tags" => ["classes"], "count" => 2, "interval" => "week" }]) if ppi.free_items.blank?
      ppi.write_attribute(:discount_items, [{ "tags" => ["classes"], "discount" => "50%" }]) if ppi.discount_items.blank?
    end

    trait :active do
      expires_at { 1.month.from_now }
      association :athlete
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end

  factory :plan_item do
    name { "Basic Plan" }

    # PlanItem setters expect tags as strings; bypass via write_attribute
    after(:build) do |pi|
      pi.write_attribute(:free_items, [{ "tags" => ["classes"], "count" => 2, "interval" => "week" }]) if pi.free_items.blank?
      pi.write_attribute(:discount_items, [{ "tags" => ["classes"], "discount" => "50%" }]) if pi.discount_items.blank?
    end
  end

  factory :redemption_key do
    line_item
    redeemed { false }

    trait :redeemed do
      redeemed { true }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :multi_use do
      can_be_used_multiple_times { true }
    end
  end

  factory :spot do
    title { "Downtown Spot" }
    description { "A great parkour spot" }
    lat { "40.7608" }
    lon { "-111.8910" }
    approved { true }
  end

  factory :rating do
    spot
    rated { 4 }
  end

  factory :image do
    spot
  end

  factory :competition do
    name { "Summer Jam 2024" }
    start_time { 2.months.from_now }
    description { "Annual parkour competition" }
    option_costs do
      {
        youth: { early: { "Speed" => 25, "Freestyle" => 30 }, late: { "Speed" => 35, "Freestyle" => 40 } },
        adult: { early: { "Speed" => 35, "Freestyle" => 40 }, late: { "Speed" => 45, "Freestyle" => 50 } }
      }
    end
    coupon_codes { { "HALF" => "cost * 0.5", "TEN" => "cost - 10" } }
  end

  factory :competitor do
    athlete
    competition
    selected_comp { "Speed" }
    age { 20 }
    shirt_size { "M" }
    sort_order { nil }

    trait :youth do
      age { 10 }
      after(:build) do |c|
        c.athlete.update_column(:date_of_birth, "01/15/#{Date.current.year - 10}") if c.athlete.persisted?
      end
    end

    trait :approved do
      approved_at { Time.current }
    end
  end

  factory :competition_judgement do
    competitor
    association :judge, factory: [:user, :instructor]
    category { "Judge 1" }
    category_score { 8.5 }
    overall_impression { 7.0 }
  end

  factory :chat_room do
    sequence(:name) { |n| "Room #{n}" }
    visibility_level { :global }
    message_type { :chat }

    trait :text_room do
      sequence(:name) { |n| "801555#{n.to_s.rjust(4, '0')}" }
      message_type { :text }
      visibility_level { :admin }
    end

    trait :admin_only do
      visibility_level { :admin }
    end

    trait :personal do
      visibility_level { :personal }
    end
  end

  factory :chat_room_user do
    chat_room
    user
    has_unread_messages { false }
  end

  factory :message do
    chat_room
    association :sent_from, factory: :user
    body { "Hello there!" }

    trait :from_pkut do
      sent_from { nil }
      after(:build) { |m| m.sent_from_id = 0 }
    end

    trait :read do
      read_at { Time.current }
    end
  end

  factory :announcement do
    association :admin, factory: [:user, :admin]
    body { "Important announcement!" }
    expires_at { 1.week.from_now }

    trait :delivered do
      delivered_at { Time.current }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end

  factory :contact_request do
    name { "John Doe" }
    email { "john@example.com" }
    phone { "8015551234" }
    body { "I want to learn parkour!" }
    success { true }
  end

  factory :event_subscription do
    user
    event_schedule
  end

  factory :emergency_contact do
    user
    name { "Emergency Person" }
    number { "8015559999" }
  end

  factory :unlimited_subscription do
    user
    expires_at { 1.month.from_now }
    usages { 0 }
  end

  factory :log_tracker do
    url { "/some/path" }
    http_method { "GET" }
    ip_address { "127.0.0.1" }
  end
end
