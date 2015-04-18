class WelcomeMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def welcome_mail(email)
    mail(to: email, subject: "Thanks for signing up at ParkourUtah!")
  end
end
