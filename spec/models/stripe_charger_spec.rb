require 'rails_helper'

RSpec.describe StripeCharger do
  describe ".charge" do
    it "calls Stripe::Charge.create with correct params" do
      charge_double = double("charge", status: "succeeded")
      expect(Stripe::Charge).to receive(:create).with(
        hash_including(source: "tok_test", amount: 5000, currency: "usd")
      ).and_return(charge_double)

      result = StripeCharger.charge("tok_test", 5000)
      expect(result.status).to eq("succeeded")
    end

    it "merges additional params" do
      charge_double = double("charge")
      expect(Stripe::Charge).to receive(:create).with(
        hash_including(source: "tok_test", amount: 5000, currency: "usd", description: "Test")
      ).and_return(charge_double)

      StripeCharger.charge("tok_test", 5000, description: "Test")
    end

    it "handles Stripe::CardError" do
      allow(Stripe::Charge).to receive(:create).and_raise(Stripe::CardError.new("declined", "param"))
      result = StripeCharger.charge("tok_test", 5000)
      expect(result[:failure_message]).to include("Failed to Charge")
    end

    it "handles general errors" do
      allow(Stripe::Charge).to receive(:create).and_raise(StandardError.new("network error"))
      result = StripeCharger.charge("tok_test", 5000)
      expect(result[:failure_message]).to include("Failed to Charge")
    end
  end
end
