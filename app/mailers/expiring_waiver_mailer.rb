class ExpiringWaiverMailer < ApplicationMailer
  default template_path: "mailers/#{self.name.underscore}"

  def expiring_waiver_mail(athlete_id)
    @athlete = Dependent.find(athlete_id.to_i)

    mail(to: @athlete.user.email, subject: "#{@athlete.full_name}'s waiver expires soon!")
  end

  def notify_subscription_updating(user_id)
    @user = User.find(user_id)
    range = (10.days.from_now.beginning_of_day..10.days.from_now.end_of_day)
    @expiring_athletes = @user.dependents.joins(:athlete_subscriptions).where('athlete_subscriptions.expires_at > ? AND athlete_subscriptions.expires_at < ?', range.min, range.max).where('athlete_subscriptions.auto_renew = true')
    @expiring_athletes = @expiring_athletes.select { |a| range.cover?(a.subscription.expires_at) }
    return nil unless @expiring_athletes.any?

    mail(to: @user.email, subject: "Your recurring payment will charge again soon!")
  end

end
