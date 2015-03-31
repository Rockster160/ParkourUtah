class LowCreditsMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def low_credits_mail(user_id)
    @user = User.find(user_id.to_i)

    mail(to: @user.email, subject: "You are almost out of class credits!")
  end
end
