class ClassReminderMailerWorker
  include Sidekiq::Worker

  def perform(user_id, msg)
    ClassReminderMailer.class_reminder_mail(user_id, msg).deliver_now
  end

end
