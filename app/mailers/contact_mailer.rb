class ContactMailer < ApplicationMailer

  def help_mail(params)
    @name = params["name"]
    @email = params["email"]
    @phone = params["phone"]
    @body = params["comment"]
    mail(to: "rocco11nicholls@gmail.com", subject: "Request for Contact")
  end
end
