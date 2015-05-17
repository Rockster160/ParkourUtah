class ClassReminderMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def class_reminder_mail(user_id, msg)
    @user = User.find(user_id.to_i)
    @msg = msg

    mail(to: @user.email, subject: "Class Reminder")
  end
end
