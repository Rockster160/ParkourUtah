class ItemsPurchasedMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def customer_purchase_mail(cart_id, email)
    @cart = Cart.find(cart_id.to_i)
    @order_items = @cart.transactions
    if @cart.user
      @user = @cart.user
      @address = @user.address
    end

    mail(to: email, subject: "Order confirmation")
  end
end
