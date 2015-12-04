class ClassReminderMailerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(user_id, msg)
    ClassReminderMailer.class_reminder_mail(user_id, msg).deliver_now
  end

end
