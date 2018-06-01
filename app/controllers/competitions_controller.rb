class CompetitionsController < ApplicationController

  def index
    @competitions = Competition.current.by_most_recent(:start_time)
  end

  def show
    redirect_to new_user_session_path, notice: "Please sign in before registering for a competition" unless user_signed_in?

  end

end
