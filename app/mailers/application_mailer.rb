class ApplicationMailer < ActionMailer::Base
  default from: ENV['PKUT_GMAIL']
  # default from: "service@parkourutah.com"
  layout 'mailer'
end
