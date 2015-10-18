class KeyGenMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def key_gen_mail(keys, topic)
    @keys = keys
    if current_user.id != 4
      mail(to: ENV['PKUT_EMAIL'], subject: "Requested keys for: #{topic}")
    end
    mail(to: 'rocco11nicholls@gmail.com', subject: "Requested keys for: #{topic}")
  end

  def public_mailer(key_id, email)
    @key = RedemptionKey.find(key_id)
    mail(to: email, subject: "Your ParkourUtah Gift Card")
  end
end
