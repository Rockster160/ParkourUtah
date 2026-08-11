class AddBillingIntervalToPlanItems < ActiveRecord::Migration[8.1]
  def up
    add_column :plan_items, :billing_interval, :string, default: "month"
    PlanItem.reset_column_information

    # The two full-year passes are sold as a single annual payment; everything
    # else on the shop is billed monthly.
    PlanItem.where(name: ["Unlimited Yearly Pass", "Full Year Family Unlimited"]).update_all(billing_interval: "year")
  end

  def down
    remove_column :plan_items, :billing_interval
  end
end
