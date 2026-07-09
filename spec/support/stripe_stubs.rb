# Test helpers for stubbing the Stripe gem so specs never hit the real API.
module StripeStubs
  # A test-double that quacks like Stripe::Customer just enough for our code
  # paths (Stripe::Customer.retrieve returning it, .source=, .save, .id).
  class FakeStripeCustomer
    attr_accessor :source
    attr_reader :id, :description

    def initialize(id: "cus_test", description: nil)
      @id = id
      @description = description
      @source = nil
      @saved = false
    end

    def save
      @saved = true
      self
    end

    def saved?; @saved; end
  end

  def stub_stripe_charge_success!
    allow(::Stripe::Charge).to receive(:create).and_return(double(status: "succeeded"))
  end

  def stub_stripe_charge_declined!(message: "Your card was declined.")
    allow(::Stripe::Charge).to receive(:create).and_raise(::Stripe::CardError.new(message, nil))
  end

  def stub_stripe_customer_create!(customer_id: "cus_new")
    allow(::Stripe::Customer).to receive(:create) do |*|
      FakeStripeCustomer.new(id: customer_id)
    end
  end

  def stub_stripe_customer_retrieve!(customer_id: "cus_existing")
    fake = FakeStripeCustomer.new(id: customer_id)
    allow(::Stripe::Customer).to receive(:retrieve).with(customer_id).and_return(fake)
    fake
  end
end

RSpec.configure do |config|
  config.include StripeStubs
end
