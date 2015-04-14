class NewAthleteInfoMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def new_athlete_info_mail(athlete_ids)
    @athletes = athlete_ids.map { |athlete_id| Dependent.find(athlete_id) }

    mail(to: @athletes.first.user.email, subject: "New Athlete Information")
  end
end
