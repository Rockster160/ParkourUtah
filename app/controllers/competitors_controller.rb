class CompetitorsController < ApplicationController

  def create
    @competition = Competition.find(competitor_params[:competition_id])
    @eligible_athletes = current_user.athletes.where.not(id: @competition.competitors.pluck(:athlete_id))
    @competitor = Competitor.create(competitor_params)

    unless @competitor.persisted?
      flash.now[:alert] = "Failed to create competitor. Please try again."
      render "competitions/show"
    end

    athlete = @competitor.athlete
    charge = StripeCharger.charge(params[:stripeToken], 2500, description: "#{@competition.name} Competitor: #{athlete.full_name}")

    if charge.try(:status) == "succeeded"
      slack_message = "New *#{@competition.name}* Competitor: *#{athlete.full_name}*\n<#{admin_user_url(athlete.user)}|Click here to view their account.>"
      SlackNotifier.notify(slack_message, Rails.env.production? ? "#special-purchases" : "#slack-testing")
      redirect_to account_path, notice: "#{athlete.full_name} is enrolled in #{@competition.name}. See you there!"
    else
      @competitor.try(:destroy)
      flash.now[:alert] = charge&.dig(:failure_message).presence || "Failed to charge card. Please verify you entered the correct details or contact your banking institution."
      render "competitions/show"
    end
  end

  private

  def competitor_params
    params.require(:competitor).permit(
      :competition_id,
      :athlete_id,
      :years_training,
      :instagram_handle,
      :song,
      :bio
    )
  end

end
