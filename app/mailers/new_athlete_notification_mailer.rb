class NewAthleteNotificationMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def new_athlete_notification_mail(text)
    mail(to: ENV["PKUT_EMAIL"], subject: "Somebody made some athletes!")
  end
end
