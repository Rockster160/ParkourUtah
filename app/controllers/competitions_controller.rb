class CompetitionsController < ApplicationController

  def index
    @competitions = Competition.current.by_most_recent(:start_time)
  end

  def show
    redirect_to new_user_session_path, notice: "Please sign in before registering for a competition" unless user_signed_in?
    @competition = Competition.current.find(params[:id])
    @competitor = @competition.competitors.new
    @eligible_athletes = current_user.athletes.where.not(id: @competition.competitors.pluck(:athlete_id))
  end

end
