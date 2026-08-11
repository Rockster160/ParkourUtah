require 'rails_helper'

RSpec.describe "Account page", type: :request do
  let(:user) { create(:user, :with_address, registration_complete: true) }
  let(:athlete) { create(:athlete, user: user) }
  before { sign_in user }

  describe "subscription notifications" do
    it "warns when an auto-renewing plan has no card on file" do
      create(:purchased_plan_item, :active,
        user: user, athlete: athlete, plan_item: create(:plan_item),
        auto_renew: true, stripe_id: nil
      )

      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("We don&#39;t have a card on file")
    end

    it "stays quiet when the plan has a card on file" do
      create(:purchased_plan_item, :active,
        user: user, athlete: athlete, plan_item: create(:plan_item),
        auto_renew: true, stripe_id: "cus_ok"
      )

      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("We don&#39;t have a card on file")
    end
  end

  describe "athletes without a waiver" do
    it "renders rather than raising on the missing waiver record" do
      athlete # no waiver created for them

      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Must have waiver signed before attending class.")
    end
  end
end
