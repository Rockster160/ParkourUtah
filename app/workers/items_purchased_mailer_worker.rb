class ItemsPurchasedMailerWorker
  include Sidekiq::Worker

  def perform(cart_id, email)
    unless email
      cart = Cart.find(cart_id)
      user = cart.user
      email ||= user.email
      email ||= cart.email
    end
    ItemsPurchasedMailer.customer_purchase_mail(cart_id, email).deliver_now
  end

end
