class CompetitionsController < ApplicationController
  before_action :validate_instructor, except: [:index, :show, :results]

  def index
    @competitions = Competition.current.by_most_recent(:start_time)
  end

  def show
    return redirect_to new_user_session_path, notice: "Please sign in before registering for a competition" unless user_signed_in?
    @competition = Competition.current.find(params[:id])
    @competitor = @competition.competitors.new
    @eligible_athletes = current_user.athletes.where.not(id: @competition.competitors.pluck(:athlete_id))
    @registered_athletes = current_user.athletes.where(id: @competition.competitors.pluck(:athlete_id))
  end

  def results
    competition = Competition.find(params[:competition_id])

    render json: competition.competitor_hash
  end

  def judge
    @competition = Competition.find(params[:competition_id])
  end

  def category
    @competition = Competition.find(params[:competition_id])
    @competitors = @competition.competitors.approved.order(:sort_order)
    @category = params[:category]
  end

  def competitor
    @competition = Competition.find(params[:competition_id])
    @competitor = @competition.competitors.find(params[:competitor_id])
    @category = params[:category]
  end

  def monitor
    @competition = Competition.find(params[:competition_id])
    @competitors = @competition.competitors.approved.order(:sort_order)
    @categories = CompetitionJudgement.categories.keys.map(&:titleize)
  end

  def judge_competitor
    @competition = Competition.find(params[:competition_id])
    @competitor = @competition.competitors.find(params[:competitor_id])
    @category = params[:category]

    judged = @competitor.competition_judgements.by_category(@category).first_or_initialize
    judged.judge = current_user
    judged.category_score = params.dig(:competition_judgement, :category_score)
    judged.overall_impression = params.dig(:competition_judgement, :overall_impression)
    judged.save

    redirect_to competition_category_path(@competition, @category)
  end

end
