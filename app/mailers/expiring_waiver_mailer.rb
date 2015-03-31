class ExpiringWaiverMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def expiring_waiver_mail(athlete_id)
    @athlete = Dependent.find(athlete_id.to_i)

    mail(to: @athlete.user.email, subject: "#{@athlete.full_name}'s waiver expires soon!")
  end
end
