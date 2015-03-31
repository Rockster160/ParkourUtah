class PinResetMailer < ApplicationMailer

  def pin_reset_mail(athlete_id)
    @athlete = Dependent.find(athlete_id.to_i)

    mail(to: @athlete.user.email, subject: "Request for ID or Pin Reset")
  end
end
