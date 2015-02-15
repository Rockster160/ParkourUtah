class PeepsController < ApplicationController

  def show
    @mod = User.find(params[:id])
    redirect_to root_path unless @mod.is_mod?
  end
end
