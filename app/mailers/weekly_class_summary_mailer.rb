class WeeklyClassSummaryMailer < ApplicationMailer

  def weekly_summary_mail(summary)
    @summary = summary[0]
    @payment = summary[1]
    dates = (0..6).map {|t| (Time.now - t.days).strftime("%B %-d, %Y")}.reverse
    mail(to: "rocco11nicholls@gmail.com", subject: "Weekly summary for #{dates.first} - #{dates.last}")
  end
end
