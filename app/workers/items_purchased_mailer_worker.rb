class ItemsPurchasedMailerWorker
  include Sidekiq::Worker

  def perform(cart_id, email)
    ItemsPurchasedMailer.customer_purchase_mail(cart_id, email).deliver_now
  end

end
