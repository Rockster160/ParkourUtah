class WelcomeMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def welcome_mail(email)
    mail(to: email, subject: "Thanks for signing up at ParkourUtah!")
  end

  def temp_mail(email)
    mail(to: email, subject: "ParkourUtah Flip Clinic")
  end

end
