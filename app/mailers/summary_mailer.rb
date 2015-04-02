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


=begin
@classes = {
  class = [
    "name - payment_type",6155 5194
    "name - payment_type"
  ],
  class = [
    "name - payment_type",
    "name - payment_type",
    "name - payment_type",
    "name - payment_type"
  ]
}

March 15, 2015

Intermediate - Sandy
  Marcos
    Rocco - Cash
    Kim - Credits

Fundamentals - Draper
  Justin
    Sam - Credits

=end
