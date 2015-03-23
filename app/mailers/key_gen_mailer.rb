class ContactMailer < ApplicationMailer

  def key_gen_mail(keys)
    @keys = keys
    mail(to: "rocco11nicholls@gmail.com", subject: "Requested keys for: #{@keys.first.redemption}")
  end
end
