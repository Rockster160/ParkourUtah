class SummaryMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def summary_mail(summary)
    @summary = summary[0]
    @payment = summary[1]
    range = summary.first.keys
    dates = range.length == 1 ? "for #{range.first}." : "from #{range.last} to #{range.first}."
    mail(to: ENV['PKUT_EMAIL'], subject: "Class summary #{dates}")
  end
end
