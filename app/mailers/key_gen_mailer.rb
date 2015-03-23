class KeyGenMailer < ApplicationMailer

  def key_gen_mail(keys, topic)
    @keys = keys
    mail(to: "rocco11nicholls@gmail.com", subject: "Requested keys for: #{topic}")
  end
end
