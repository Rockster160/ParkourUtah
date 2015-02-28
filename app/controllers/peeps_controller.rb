class PeepsController < ApplicationController
  layout 'application', except: [:secret]

  def show
    @instructor = User.find(params[:id])
    redirect_to root_path unless @instructor.is_instructor?
  end

  def secret
    # @user = User.first
  end

  def secret_submit
    id, pin = params[:pin].split('-')
    flash[:notice] = "User: #{id}, PIN: #{pin}"
    # if User.first.update(first_name: params[:user][:first_name])
    #   flash[:notice] = "Success! "
    # else
    #   flash[:alert] = "Failure..."
    # end
    redirect_to root_path
  end
end
