class NewAthleteInfoMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def new_athlete_info_mail(athlete_id)
    @athlete = Dependent.find(athlete_id.to_i)

    mail(to: @athlete.user.email, subject: "New Athlete Information")
  end
end
