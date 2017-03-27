class AnnouncementsController < ApplicationController
  before_action :validate_admin, except: [ :view ]

  def view
    current_user.announcement_views.create(announcement_id: current_user.announcement_to_see.id)
    head :ok
  end

  def deliver
    @announcement = Announcement.find(params[:id])

    if @announcement.deliver
      redirect_to announcements_path, notice: "Delivered!"
    else
      redirect_to edit_announcement_path(@announcement), alert: "Something went wrong!"
    end
  end

  def index
    @announcements = Announcement.by_most_recent(:created_at)
  end

  def new
    @announcement = Announcement.new
  end

  def create
    @announcement = current_user.announcements.new(announcement_params)

    if @announcement.save
      redirect_to edit_announcement_path(@announcement), notice: "Successfully created announcement! Preview here, and click 'Deliver' to deliver the Announcement to users."
    else
      flash.now[:alert] = "Failed to create announcement."
      render :new
    end
  end

  def edit
    @announcement = Announcement.find(params[:id])
  end

  def update
    @announcement = Announcement.find(params[:id])

    if @announcement.update(announcement_params)
      redirect_to edit_announcement_path(@announcement), notice: "Successfully updated announcement!"
    else
      flash.now[:alert] = "Failed to update announcement."
      render :edit
    end
  end

  def destroy
    @announcement = Announcement.find(params[:id])

    if @announcement.destroy
      redirect_to announcements_path, notice: "Successfully destroyed announcement!"
    else
      redirect_to edit_announcement_path(@announcement), alert: "Failed to destroy that announcement."
    end
  end

  private

  def announcement_params
    params.require(:announcement).permit(:body, :expires_at_date, :expires_at_time)
  end

end
