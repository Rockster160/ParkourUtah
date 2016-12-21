class InstructorsController < ApplicationController
  before_action :validate_admin

  def index
    @instructors = User.instructors.order(instructor_position: :asc)
  end

  def show
    @instructor = User.instructors.find(params[:id])
  end

  def new
    @instructor = User.new
  end

  def create
    new_pass = "UTPKFR4LF"
    new_user = false
    instructor = User.find_by_email(params[:user][:email])
    new_user = true if instructor.nil?
    instructor ||= User.new(email: params[:user][:email], password: new_pass)
    instructor.update(instructor_params)
    if instructor.save
      number_of_instructors = User.instructors.count
      instructor.update(role: 1, instructor_position: number_of_instructors + 1)
      flash[:notice] = "Instructor successfully created with password: #{new_pass}." if new_user == true
      flash[:notice] = "Instructor successfully promoted." if new_user == false
    else
      flash[:alert] = "There was an error adding the instructor."
    end
    redirect_to instructors_path
  end

  def edit
    @instructor = User.instructors.find(params[:id])
  end

  def update
    if User.find(params[:id]).update(instructor_params)
      flash[:notice] = "Instructor successfully updated."
    else
      flash[:alert] = "There was an error updating the instructor."
    end
    redirect_to instructors_path
  end

  def destroy
    @instructor = User.instructors.find(params[:id])
    if @instructor.update(role: 0)
      User.update_instructor_positions
      redirect_to instructors_path, notice: "Successfully demoted Instructor"
    else
      redirect_to instructors_path, alert: "There was an error demoting that Instructor."
    end
  end

  def update_position
    @instructor = User.find(params[:id])
    @instructor.update(instructor_position: params["instructor"]["instructor_position"].to_i)
    respond_to do |format|
      format.json { render json: @instructor }
    end
  end

  private

  def instructor_params
    params.require(:user).permit(
      :email,
      :first_name,
      :last_name,
      :nickname,
      :stats,
      :payment_multiplier,
      :title,
      :bio,
      :avatar,
      :avatar_2,
      :role
    )
  end

end
