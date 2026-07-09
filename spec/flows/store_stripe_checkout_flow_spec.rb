require 'rails_helper'

# Focused on the Stripe-touching parts of the checkout flow: which sub records
# get created for each LineItem shape, and whether a Stripe customer gets set
# up so the monthly worker can find it later.
RSpec.describe "Store checkout — Stripe side effects", type: :request do
  let(:user) { create(:user, :with_address, credits: 0) }
  before { sign_in user }

  before do
    stub_stripe_customer_create!(customer_id: "cus_checkout")
    stub_stripe_charge_success!
  end

  it "creates a Stripe customer AND a PurchasedPlanItem for a plans-only line item" do
    plan_item = create(:plan_item)
    li = create(:line_item, cost_in_pennies: 6500, category: "Class", credits: 0)
    li.update_column(:plan_item_id, plan_item.id)
    user.cart.cart_items.create!(line_item: li, amount: 1, order_name: li.title)

    post charge_path, params: { stripeToken: "tok_visa" }

    expect(::Stripe::Customer).to have_received(:create).with(
      hash_including(source: "tok_visa")
    )
    ppi = user.purchased_plan_items.last
    expect(ppi).to be_present
    expect(ppi.stripe_id).to eq("cus_checkout")
    expect(ppi.cost_in_pennies).to eq(6500)
    expect(user.recurring_subscriptions.count).to eq(0)
  end

  it "creates a RecurringSubscription (not a PPI) for a non-plan is_subscription line item" do
    li = create(:line_item, :subscription, cost_in_pennies: 5500)
    user.cart.cart_items.create!(line_item: li, amount: 1, order_name: li.title)

    post charge_path, params: { stripeToken: "tok_visa" }

    rs = user.recurring_subscriptions.last
    expect(rs).to be_present
    expect(rs.stripe_id).to eq("cus_checkout")
    expect(rs.cost_in_pennies).to eq(5500)
    expect(user.purchased_plan_items.count).to eq(0)
  end

  it "creates ONLY a PPI for a hybrid line item (regression: prevents double-billing)" do
    plan_item = create(:plan_item)
    li = create(:line_item, :subscription, cost_in_pennies: 17000)
    li.update_column(:plan_item_id, plan_item.id)
    user.cart.cart_items.create!(line_item: li, amount: 1, order_name: li.title)

    post charge_path, params: { stripeToken: "tok_visa" }

    expect(user.purchased_plan_items.count).to eq(1)
    expect(user.recurring_subscriptions.count).to eq(0)
  end

  it "locks in the actual paid unit price (loyalty/bundle applied) on the sub record" do
    plan_item = create(:plan_item)
    li = create(:line_item, cost_in_pennies: 13000,
      bundle_amount: 2, bundle_cost_in_pennies: 12200,
      category: "Class", credits: 0)
    li.update_column(:plan_item_id, plan_item.id)
    # amount=2 triggers bundle pricing.
    user.cart.cart_items.create!(line_item: li, amount: 2, order_name: li.title)

    post charge_path, params: { stripeToken: "tok_visa" }

    # Two PPIs (one per unit), each locked in at the paid per-unit price.
    expect(user.purchased_plan_items.count).to eq(2)
    expect(user.purchased_plan_items.pluck(:cost_in_pennies).uniq).to eq([12200])
  end

  it "creates one Stripe customer per checkout regardless of number of PPIs" do
    plan_item = create(:plan_item)
    li = create(:line_item, cost_in_pennies: 6500, category: "Class", credits: 0)
    li.update_column(:plan_item_id, plan_item.id)
    user.cart.cart_items.create!(line_item: li, amount: 2, order_name: li.title)

    post charge_path, params: { stripeToken: "tok_visa" }

    expect(::Stripe::Customer).to have_received(:create).once
    expect(user.purchased_plan_items.count).to eq(2)
    expect(user.purchased_plan_items.pluck(:stripe_id).uniq).to eq(["cus_checkout"])
  end

  it "does not create a Stripe customer for a non-subscription cart (e.g. clothing only)" do
    li = create(:line_item, :clothing, cost_in_pennies: 2500)
    user.cart.cart_items.create!(line_item: li, amount: 1, order_name: li.title)

    post charge_path, params: { stripeToken: "tok_visa" }

    expect(::Stripe::Customer).not_to have_received(:create)
    expect(user.purchased_plan_items.count).to eq(0)
    expect(user.recurring_subscriptions.count).to eq(0)
  end
end
