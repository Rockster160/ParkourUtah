class ItemsPurchasedMailerPreview < ActionMailer::Preview

  def customer_purchase_mail
    email = 'rocco11nicholls@gmail.com'
    cart = User[4].cart
    ItemsPurchasedMailer.customer_purchase_mail(cart.id, email)
  end

end
