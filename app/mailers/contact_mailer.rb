class ContactMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def help_mail(params)
    @name = params["name"]
    @email = params["email"]
    @phone = params["phone"]
    @body = params["comment"]
    mail(to: "justin@parkourutah.com", subject: "Request for Contact")
  end
end
