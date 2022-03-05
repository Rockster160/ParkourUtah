class StripeCharger

  def self.charge(token, amount, additional_params={})
    Stripe::Charge.create({
      source: token,
      amount: amount,
      currency: "usd"
    }.merge(additional_params))
  rescue Stripe::CardError => e
    {failure_message: "Failed to Charge: #{e}"}
  rescue StandardError => e
    CustomLogger.log("\e[31mOther error: \n#{e}\e[0m")
    {failure_message: "Failed to Charge, try logging out and back in or trying a different browser."}
  end

end
