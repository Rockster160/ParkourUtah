class ItemsPurchasedMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def customer_purchase_mail(cart_id, email)
    @cart = Cart.find(cart_id.to_i)
    @order_items = @cart.transactions
    @is_gift_card = @order_items.any? { |transaction| ["Gift Card"].include?(transaction.item.category) }
    @is_physical = @order_items.any? { |transaction| ["Clothing", "Accessories"].include?(transaction.item.category) }
    @adds_credits = @order_items.any? { |transaction| transaction.item.credits > 0 }
    @is_subscription = @order_items.any? { |transaction| transaction.item.is_subscription? }
    if @cart.user
      @user = @cart.user
      @address = @user.address
    end

    mail(to: email, subject: "Order confirmation")
  end
end
