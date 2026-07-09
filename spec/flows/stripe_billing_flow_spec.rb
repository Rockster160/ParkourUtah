require 'rails_helper'

RSpec.describe "Stripe billing flow", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /user/update_card_details — no prior Stripe customer" do
    let!(:athlete) { create(:athlete, user: user) }

    it "creates a new Stripe customer and populates stripe_id on the user's auto-renewing PPI" do
      ppi = create(:purchased_plan_item, :active,
        user: user, athlete: athlete,
        cost_in_pennies: 6500, stripe_id: nil
      )
      stub_stripe_customer_create!(customer_id: "cus_brand_new")
      allow(::Stripe::Charge).to receive(:create) # future-expiry, no immediate charge

      post update_card_details_user_path, params: { stripeToken: "tok_visa" }

      expect(::Stripe::Customer).to have_received(:create).with(
        hash_including(source: "tok_visa", description: user.email)
      )
      expect(ppi.reload.stripe_id).to eq("cus_brand_new")
      expect(flash[:notice]).to match(/Card updated successfully/)
      expect(flash[:alert]).to be_nil
    end

    it "immediately charges Stripe for a past-due PPI (user 6763 scenario)" do
      overdue = create(:purchased_plan_item, :expired,
        user: user, athlete: athlete,
        cost_in_pennies: 6500, stripe_id: nil
      )
      stub_stripe_customer_create!(customer_id: "cus_first_time")
      stub_stripe_charge_success!

      post update_card_details_user_path, params: { stripeToken: "tok_visa" }

      expect(::Stripe::Charge).to have_received(:create).with(
        hash_including(amount: 6500, currency: "usd", customer: "cus_first_time")
      )
      expect(overdue.reload.auto_renew).to eq(false)
      new_ppi = user.purchased_plan_items.where(auto_renew: true).first
      expect(new_ppi).to be_present
      expect(new_ppi.expires_at).to be_within(2.minutes).of(1.month.from_now)
      expect(flash[:notice]).to include("$65.00")
    end
  end

  describe "POST /user/update_card_details — with an existing Stripe customer" do
    let!(:athlete) { create(:athlete, user: user) }

    it "retrieves and updates the existing customer rather than creating a new one" do
      create(:recurring_subscription,
        user: user, athlete: athlete,
        expires_at: 3.days.ago, cost_in_pennies: 5500,
        stripe_id: "cus_existing"
      )
      customer = stub_stripe_customer_retrieve!(customer_id: "cus_existing")
      allow(::Stripe::Customer).to receive(:create)
      stub_stripe_charge_success!

      post update_card_details_user_path, params: { stripeToken: "tok_new_card" }

      expect(::Stripe::Customer).to have_received(:retrieve).with("cus_existing")
      expect(::Stripe::Customer).not_to have_received(:create)
      expect(customer.source).to eq("tok_new_card")
      expect(customer).to be_saved
    end
  end

  describe "POST /user/update_card_details — future-expiry (user 6803 scenario)" do
    let!(:athlete) { create(:athlete, user: user) }

    it "populates stripe_id but does NOT trigger an immediate charge" do
      create(:purchased_plan_item, :active,
        user: user, athlete: athlete,
        cost_in_pennies: 6500, stripe_id: nil,
        expires_at: 1.month.from_now
      )
      stub_stripe_customer_create!(customer_id: "cus_deferred")
      allow(::Stripe::Charge).to receive(:create)

      post update_card_details_user_path, params: { stripeToken: "tok_visa" }

      expect(::Stripe::Charge).not_to have_received(:create)
      expect(user.purchased_plan_items.pluck(:stripe_id).uniq).to eq(["cus_deferred"])
    end
  end

  describe "POST /user/update_card_details — Stripe declines the missed charge" do
    let!(:athlete) { create(:athlete, user: user) }

    it "still saves the card, flags the PPI card_declined, and shows a partial-success message" do
      overdue = create(:purchased_plan_item, :expired,
        user: user, athlete: athlete,
        cost_in_pennies: 6500, stripe_id: nil
      )
      stub_stripe_customer_create!(customer_id: "cus_saved_ok")
      stub_stripe_charge_declined!

      post update_card_details_user_path, params: { stripeToken: "tok_declined" }

      # Card save succeeded.
      expect(overdue.reload.stripe_id).to eq("cus_saved_ok")
      # Missed-charge failed → card_declined flagged, no renewal record created.
      expect(overdue.reload.card_declined).to be_present
      expect(user.purchased_plan_items.count).to eq(1)
      expect(flash[:notice]).to include("Card updated successfully")
      expect(flash[:alert]).to include("retry on the next scheduled run")
    end
  end

  describe "POST /user/update_card_details — Stripe customer save itself fails" do
    let!(:athlete) { create(:athlete, user: user) }

    it "bails without touching sub state" do
      ppi = create(:purchased_plan_item, :active,
        user: user, athlete: athlete, stripe_id: nil
      )
      allow(::Stripe::Customer).to receive(:create).and_raise(::Stripe::APIConnectionError.new("network down"))

      post update_card_details_user_path, params: { stripeToken: "tok_visa" }

      expect(ppi.reload.stripe_id).to be_blank
      expect(flash[:alert]).to include("error updating your card")
      expect(flash[:notice]).to be_nil
    end
  end
end
