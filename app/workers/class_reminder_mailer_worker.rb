class ClassReminderMailerWorker
  include Sidekiq::Worker

  def perform(user_id, msg)
    ClassReminderMailer.customer_purchase_mail(user_id, msg).deliver_now
  end

end
