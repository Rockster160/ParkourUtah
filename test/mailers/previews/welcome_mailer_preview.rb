class WelcomeMailerPreview < ActionMailer::Preview

  def temp_mail
    email = 'rocco11nicholls@gmail.com'
    WelcomeMailer.temp_mail(email)
  end

end
