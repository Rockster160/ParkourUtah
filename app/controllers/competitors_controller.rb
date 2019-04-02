class CompetitorsController < ApplicationController
  before_action :validate_admin, only: :update

  def complete
    @competitor = Competitor.find(params[:id])
  end

  def create
    @competition = Competition.find(competitor_params[:competition_id])
    @eligible_athletes = current_user.athletes.where.not(id: @competition.competitors.pluck(:athlete_id))
    @registered_athletes = current_user.athletes.where(id: @competition.competitors.pluck(:athlete_id))
    @competitor = Competitor.create(competitor_params)

    unless @competitor.persisted?
      flash.now[:alert] = "Failed to create competitor. Please try again."
      return render "competitions/show"
    end

    athlete = @competitor.athlete
    # athlete.update(athlete_photo: params.dig(:athlete, :photo)) if params.dig(:athlete, :photo).present?
    no_charge = @competitor.discounted_cost == 0
    charge = StripeCharger.charge(params[:stripeToken], (@competitor.discounted_cost * 100).round, description: "#{@competition.name} Competitor: #{athlete.full_name} for #{@competitor.selected_comp}") unless no_charge

    if no_charge || charge.try(:status) == "succeeded"
      @competitor.update(stripe_charge_id: charge[:id]) if charge.present?
      ApplicationMailer.registered_competitor(@competitor.id).deliver_later
      slack_message = "New *<#{competition_url(@competition)}|#{@competition.name}>* Competitor: *#{athlete.full_name}*\n<#{admin_user_url(athlete.user)}|Click here to view their account.>"
      SlackNotifier.notify(slack_message, Rails.env.production? ? "#special-purchases" : "#slack-testing")
      redirect_to complete_competitor_path(@competitor), notice: "#{athlete.full_name} is enrolled in #{@competition.name}. See you there!"
    else
      @competitor.try(:destroy)
      flash.now[:alert] = charge&.dig(:failure_message).presence || "Failed to charge card. Please verify you entered the correct details or contact your banking institution."
      render "competitions/show"
    end
  end

  def update
    @competitor = Competitor.find(params[:id])
    @competitor.update(approved_at: DateTime.current)
    ApplicationMailer.approved_competitor(@competitor.id).deliver_later
    redirect_to competition_path(@competitor.competition)
  end

  private

  def competitor_params
    params.require(:competitor).permit(
      :competition_id,
      :athlete_id,
      :years_training,
      :instagram_handle,
      :song,
      :referred_by,
      :bio,
      :selected_comp,
      :shirt_size,
      :coupon_code
    )
  end

end
