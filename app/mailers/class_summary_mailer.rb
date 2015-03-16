class ClassSummaryMailer < ApplicationMailer

  def summary_mail(params)
    @date = Time.now.strftime("%B %-d, %Y")
    @classes = params
    mail(to: "rocco11nicholls@gmail.com", subject: "Class summary for #{@date}")
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
