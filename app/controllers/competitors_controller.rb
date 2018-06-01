class CompetitorsController < ApplicationController

  def create
    @competition = Competition.find(competitor_params[:competition_id])
    @eligible_athletes = current_user.athletes.where.not(id: @competition.competitors.pluck(:athlete_id))
    @competitor = Competitor.create(competitor_params)

    render "competitions/new" unless @competitor.persisted?

    

    redirect_to competitions_path, notice: "Success!"
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


# {
#   "competitor"=>{
#     "athlete"=>"1",
#     "years_training"=>"",
#     "instagram_handle"=>"",
#     "song"=>"",
#     "bio"=>""
#   },
#   "stripeToken"=>"tok_1CY4qDKFLsydVrynL9EtnuqY",
#   "stripeTokenType"=>"card",
#   "stripeEmail"=>"rocco11nicholls@gmail.com",
#   "stripeBillingName"=>"Rocco Nicholls",
#   "stripeBillingAddressCountry"=>"United States",
#   "stripeBillingAddressCountryCode"=>"US",
#   "stripeBillingAddressZip"=>"84088-2517",
#   "stripeBillingAddressLine1"=>"8062 Lismore Ln",
#   "stripeBillingAddressCity"=>"West Jordan",
#   "stripeBillingAddressState"=>"UT",
# }
