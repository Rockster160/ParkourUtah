class BatchEmailerWorker
  include Sidekiq::Worker

  def perform(subject, body, recipients, email_type)
    emails = recipients.to_s.downcase.split(",").map(&:squish)
    if emails.any?
      emails.each do |email|
        ApplicationMailer.email(email, subject, body).deliver_later
        puts "Emailing non-user #{email}"
        sleep 0.1
      end
    else
      notification_type = "email_#{email_type}"
      notification_type = Notifications.column_names.include?(notification_type) ? notification_type : "email_newsletter"
      User.joins(:notifications).where(can_receive_emails: true, notifications: {notification_type => true}).each do |user|
        puts "Emailing #{user.email}"
        ApplicationMailer.email(user.email, subject, body, notification_type).deliver_later
        sleep 0.1
      end
    end
  end

end
