# Repairs a plan whose billing cycle drifted because its PurchasedPlanItem sat
# unassigned after purchase. An unassigned plan is invisible to
# ScheduleWorker#monthly_plan_charges, so the cycle it was paid for elapses with
# no renewal, and assigning it later restarts the clock from the assignment date
# instead of from where the customer's money actually ran out.
#
# This collects the cycle that was missed, closes the drifted record at the date
# it was genuinely paid through, and opens its successor on the correct
# schedule. The successor fields match UsersController#charge_missed_plan_group
# exactly so the record is indistinguishable from an ordinary renewal — the only
# difference is that the cycle boundaries are passed in rather than derived from
# Time.current, which is the whole point: the dates on the drifted record are the
# thing that's wrong.
#
# Nothing is destroyed. The drifted record stays on file as the paid cycle it
# really was, and the charge collected here gets its own record, so the plan's
# billing history reads straight through.
class PlanBillingRealignment
  class ChargeFailed < StandardError; end

  Result = Struct.new(:charged_in_pennies, :retired_plan, :new_plan, :error, :dry_run, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def initialize(plan:, paid_through:, next_expires_at:, amount_in_pennies: nil)
    @plan = plan
    @paid_through = paid_through
    @next_expires_at = next_expires_at
    @amount_in_pennies = amount_in_pennies || plan.cost_in_pennies
  end

  def preview
    [
      "user:            #{@plan.user_id} #{@plan.user.email}",
      "athlete:         #{@plan.athlete_id} #{@plan.athlete&.full_name}",
      "plan:            #{@plan.plan_item.name} (PlanItem #{@plan.plan_item_id})",
      "drifted record:  PurchasedPlanItem ##{@plan.id}",
      "  expires_at:    #{@plan.expires_at} -> #{@paid_through}",
      "  auto_renew:    #{@plan.auto_renew} -> false",
      "charge now:      #{format_money(@amount_in_pennies)} to #{@plan.stripe_id}",
      "successor:       new PurchasedPlanItem covering #{@paid_through} -> #{@next_expires_at}",
      "next charge:     #{@next_expires_at} (monthly_plan_charges runs daily at 07:00 #{Time.zone.name})",
    ]
  end

  # Charging is deliberately opt-in. A bare call is a rehearsal that touches
  # neither Stripe nor the database.
  def call(confirm: false)
    problem = precheck
    return Result.new(error: problem) if problem
    return Result.new(dry_run: true, charged_in_pennies: @amount_in_pennies) unless confirm

    Stripe.api_key = ENV['PKUT_STRIPE_SECRET_KEY']
    new_plan = nil

    begin
      PurchasedPlanItem.transaction do
        @plan.lock!
        @plan.update!(auto_renew: false, expires_at: @paid_through)

        new_plan = @plan.user.purchased_plan_items.create!(
          athlete_id: @plan.athlete_id,
          stripe_id: @plan.stripe_id,
          plan_item_id: @plan.plan_item_id,
          cost_in_pennies: @plan.cost_in_pennies,
          discount_items: @plan.discount_items,
          free_items: @plan.free_items,
          expires_at: @next_expires_at,
        )

        # Charge last. If Stripe declines, the whole transaction unwinds and we
        # are left exactly where we started rather than with a rewritten cycle
        # and no payment against it. Same ordering, and same reasoning, as
        # StoreController#create_charge.
        charge = ::Stripe::Charge.create(
          amount: @amount_in_pennies,
          currency: "usd",
          customer: @plan.stripe_id,
        )
        raise ChargeFailed, "Stripe returned status #{charge.try(:status).inspect}" unless charge.try(:status) == "succeeded"
      end
    rescue ::Stripe::CardError => e
      return Result.new(error: "Card declined: #{e.message}")
    rescue ChargeFailed => e
      return Result.new(error: e.message)
    rescue StandardError => e
      return Result.new(error: "#{e.class}: #{e.message}")
    end

    notify_slack

    Result.new(
      charged_in_pennies: @amount_in_pennies,
      retired_plan: @plan.reload,
      new_plan: new_plan,
    )
  end

  private

  def precheck
    return "plan is not assigned to an athlete" if @plan.athlete_id.blank?
    return "plan has no Stripe customer on file" if @plan.stripe_id.blank?
    return "amount must be positive (got #{@amount_in_pennies.inspect})" unless @amount_in_pennies.to_i > 0
    return "paid_through (#{@paid_through}) must fall before next_expires_at (#{@next_expires_at})" unless @paid_through < @next_expires_at
    return "already realigned — a successor covering #{@next_expires_at} exists" if successor_exists?

    nil
  end

  # Renewal records carry no cart. Finding one that already lands on the target
  # date means this ran before, and re-running would charge the customer twice.
  def successor_exists?
    @plan.user.purchased_plan_items
      .where(cart_id: nil, plan_item_id: @plan.plan_item_id, athlete_id: @plan.athlete_id, expires_at: @next_expires_at)
      .where.not(id: @plan.id)
      .exists?
  end

  def notify_slack
    SlackNotifier.notify(
      "Charged Plan Subscriptions for #{@plan.user.email} at #{format_money(@amount_in_pennies)} (billing realignment for PurchasedPlanItem ##{@plan.id}).",
      Rails.env.production? ? "#purchases" : "#slack-testing"
    )
  rescue StandardError
    # A Slack hiccup must not read as a failed charge.
  end

  def format_money(pennies)
    ActionController::Base.helpers.number_to_currency(pennies / 100.0)
  end
end
