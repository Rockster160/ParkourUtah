class AddCoversFamilyToPlanItems < ActiveRecord::Migration[8.1]
  FAMILY_PLAN_NAMES = ["Unlimited Monthly Family Pass", "Full Year Family Unlimited"].freeze

  def up
    add_column :plan_items, :covers_family, :boolean, default: false, null: false
    PlanItem.reset_column_information

    # The two family passes are sold at a flat price for the whole household,
    # but a PurchasedPlanItem only ever attaches to one athlete, so until now
    # they covered a single student. Flag them so every athlete on the account
    # is covered by the one plan.
    family_plans = PlanItem.where(name: FAMILY_PLAN_NAMES)
    family_plans.update_all(covers_family: true)

    activate_purchased_family_passes(family_plans)
  end

  def down
    remove_column :plan_items, :covers_family
  end

  private

  # A family pass now starts the moment it is bought. The ones already sold
  # went through the old flow, which left expires_at nil until the customer
  # assigned the plan to an athlete — and a family pass has no athlete to
  # assign it to, so it sat unassigned, covering nobody and never renewing.
  #
  # Start their coverage here. Anyone whose paid-for period already elapsed
  # gets a full period from today rather than a backdated expiry: they paid
  # once and got nothing for it, and a past expires_at would put them straight
  # into the overdue-renewal path and charge them again on the spot.
  def activate_purchased_family_passes(family_plans)
    PurchasedPlanItem.reset_column_information

    PurchasedPlanItem.where(plan_item_id: family_plans.select(:id), expires_at: nil).each do |plan|
      period = plan.plan_item.billing_interval == "year" ? 1.year : 1.month
      paid_through = plan.created_at + period
      expires_at = paid_through.future? ? paid_through : Time.current + period

      plan.update_columns(expires_at: expires_at)
      say "Activated family pass ##{plan.id} (user #{plan.user_id}) through #{expires_at.to_date}"
    end
  end
end
