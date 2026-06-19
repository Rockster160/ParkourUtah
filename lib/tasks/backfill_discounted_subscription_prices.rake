namespace :backfill do
  # Lock in the actual discounted price the user originally paid on their
  # currently-active subscription record(s), so future renewals stop billing
  # the full LineItem price. Going-forward only — does not modify historical
  # records past the active link of each renewal chain, and does not refund.
  #
  # Strategy:
  #   - RecurringSubscription: for each user with an active (auto_renew: true)
  #     sub, look at their most recent purchased CartItem on a subscription
  #     line_item; if discount_cost_in_pennies is set and is lower than the
  #     active sub's cost_in_pennies, update the active sub.
  #   - PurchasedPlanItem: for each active (auto_renew: true) PPI, find the
  #     originating cart (a sibling PPI with cart_id set, matched by user +
  #     stripe_id + plan_item_id, falling back to the user's most recent
  #     purchased cart for this plan_item). If the matching CartItem had
  #     discount_cost_in_pennies and it's lower than the active PPI's
  #     cost_in_pennies, update the active PPI.
  #
  # Usage:
  #   DRY_RUN=1 bundle exec rake backfill:discounted_subscription_prices  # report only
  #   bundle exec rake backfill:discounted_subscription_prices            # apply
  task discounted_subscription_prices: :environment do
    dry_run = ENV["DRY_RUN"].present?
    changes = []

    User.joins(:recurring_subscriptions)
      .where(recurring_subscriptions: { auto_renew: true })
      .distinct.find_each do |user|

      original_cart_item = CartItem
        .joins(:cart, :line_item)
        .where(carts: { user_id: user.id })
        .where.not(carts: { purchased_at: nil })
        .where(line_items: { is_subscription: true })
        .where.not(discount_cost_in_pennies: nil)
        .order("carts.purchased_at DESC")
        .first
      next unless original_cart_item

      discounted_price = original_cart_item.discount_cost_in_pennies
      next unless discounted_price.to_i > 0

      user.recurring_subscriptions.where(auto_renew: true).find_each do |sub|
        next if sub.cost_in_pennies.to_i <= discounted_price

        changes << {
          type: "RecurringSubscription",
          id: sub.id,
          user_id: user.id,
          old_cost_in_pennies: sub.cost_in_pennies,
          new_cost_in_pennies: discounted_price,
          source_cart_item_id: original_cart_item.id,
        }
        sub.update!(cost_in_pennies: discounted_price) unless dry_run
      end
    end

    PurchasedPlanItem.auto_renew.find_each do |ppi|
      # Find the originating cart-bearing PPI in this user's chain (matched by
      # plan_item + stripe_id), then locate the CartItem in that cart whose
      # line_item targets the same plan_item.
      origin_ppi = PurchasedPlanItem
        .where(user_id: ppi.user_id, plan_item_id: ppi.plan_item_id, stripe_id: ppi.stripe_id)
        .where.not(cart_id: nil)
        .order(created_at: :asc)
        .first
      origin_ppi ||= PurchasedPlanItem
        .where(user_id: ppi.user_id, plan_item_id: ppi.plan_item_id)
        .where.not(cart_id: nil)
        .order(created_at: :asc)
        .first
      next unless origin_ppi

      cart_item = CartItem
        .joins(:line_item)
        .where(cart_id: origin_ppi.cart_id, line_items: { plan_item_id: ppi.plan_item_id })
        .where.not(discount_cost_in_pennies: nil)
        .first
      next unless cart_item

      discounted_price = cart_item.discount_cost_in_pennies
      next unless discounted_price.to_i > 0
      next if ppi.cost_in_pennies.to_i <= discounted_price

      changes << {
        type: "PurchasedPlanItem",
        id: ppi.id,
        user_id: ppi.user_id,
        old_cost_in_pennies: ppi.cost_in_pennies,
        new_cost_in_pennies: discounted_price,
        source_cart_item_id: cart_item.id,
      }
      ppi.update!(cost_in_pennies: discounted_price) unless dry_run
    end

    puts "#{dry_run ? "[DRY RUN] Would update" : "Updated"} #{changes.count} subscription record(s):"
    changes.each do |c|
      puts "  #{c[:type]}##{c[:id]} (user #{c[:user_id]}): " \
           "#{c[:old_cost_in_pennies]}¢ -> #{c[:new_cost_in_pennies]}¢ " \
           "(from CartItem##{c[:source_cart_item_id]})"
    end
  end
end
