class CompetitionsController < ApplicationController
  before_action :validate_instructor, except: [:index, :show]
  before_action :redirect_to_slug, only: :show

  def index
    @competitions = Competition.current.by_most_recent(:start_time)
  end

  def show
    return unless user_signed_in?

    @competitor = @competition.competitors.new
    @eligible_athletes = current_user.athletes.where.not(id: @competition.competitors.pluck(:athlete_id))
    @registered_athletes = current_user.athletes.where(id: @competition.competitors.pluck(:athlete_id))
  end

  def new
    @competition = Competition.new

    render :form
  end

  def edit
    @competition = comp_from_id

    render :form
  end

  def create
    @competition = Competition.new

    if @competition.update(competition_params)
      redirect_to @competition
    else
      render :form
    end
  end

  def update
    @competition = comp_from_id

    if @competition.update(competition_params)
      redirect_to @competition
    else
      render :form
    end
  end

  def destroy
    @competition = comp_from_id

    if @competition.destroy
      redirect_to :competitions
    else
      render :form
    end
  end

  def export
    @competition = comp_from_id
    @competitors = @competition.competitors.approved.order(:sort_order)
    csv_str = CSV.generate do |csv|
      csv << ["Name", "Age", "Years Training", "Instagram", "Song", "Bio"]
      @competitors.each do |c|
        csv << [c.full_name, c.age, c.years_training, c.instagram_handle, c.song, c.bio]
      end
    end
    send_data csv_str, filename: "competitors_export.csv"
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

  private

  def comp_from_id
    id = params[:slug].presence || params[:id]
    Competition.find_by(slug: id) || Competition.find(id)
  end

  def competition_params
    params.require(:competition).permit(
      :name,
      :slug,
      :start_time,
      :spot_id,
      :sponsor_images,
      :description,
      option_costs: {},
    )
  end

  def redirect_to_slug
    @competition = comp_from_id

    return if params[:slug].present?
    return redirect_to "/" + @competition.slug if @competition.try(:slug).present?

    redirect_to root_path, alert: "Competition not found" if @competition.nil?
  end
end
