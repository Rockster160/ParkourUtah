class NewAthleteNotificationMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def new_athlete_notification_mail(athlete_ids)
    @athletes = athlete_ids.map { |athlete_id| Dependent.find(athlete_id) }
    @user = @athletes.first.user

    mail(to: ENV["PKUT_EMAIL"], subject: "Somebody made some athletes!")
  end
end
