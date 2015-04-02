class KeyGenMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def key_gen_mail(keys, topic)
    @keys = keys
    mail(to: "justin@parkourutah.com", subject: "Requested keys for: #{topic}")
  end
end
