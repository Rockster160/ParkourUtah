class ContactMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def help_mail(params)
    @name = params["name"]
    @email = params["email"]
    @phone = params["phone"]
    @body = params["comment"]
    mail(to: ENV['PKUT_EMAIL'], subject: "Request for Contact")
  end

  def party_mail(email)
    mail(to: email, subject: "Parkour Party!")
  end
end
