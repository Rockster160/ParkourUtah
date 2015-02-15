class StoreController < ApplicationController

  def index
    @items = LineItem.all
  end

  def new
    @item = LineItem.new
  end

  def create
    LineItem.create(item_params)
    redirect_to store_path
  end

  private

  def item_params
    params.require(:line_item).permit(:description, :title, :display, :cost)
  end
end
