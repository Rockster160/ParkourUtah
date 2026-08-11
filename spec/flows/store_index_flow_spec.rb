require 'rails_helper'

# The shop page is the only place a plan's billing cadence is shown to a
# customer, so a wrong or missing suffix is a pricing misstatement.
RSpec.describe "Store index — plan pricing labels", type: :request do
  it "labels monthly plans /month, yearly plans /year, and leaves one-off items bare" do
    # hidden deliberately left unset — items created without an explicit value
    # must still appear in the shop.
    create(:line_item, title: "Drop In Class", cost_in_pennies: 2000, category: "Class")
    create(:line_item, title: "Monthly Unlimited", cost_in_pennies: 17000, category: "Class",
      plan_item: create(:plan_item, name: "Monthly", billing_interval: "month"))
    create(:line_item, title: "Full Year Unlimited", cost_in_pennies: 170000, category: "Class",
      plan_item: create(:plan_item, name: "Yearly", billing_interval: "year"))

    get store_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("$170.00/month")
    expect(response.body).to include("$1,700.00/year")
    expect(response.body).not_to include("$1,700.00/month")
    expect(response.body).to include("$20.00<br/>")
  end
end
