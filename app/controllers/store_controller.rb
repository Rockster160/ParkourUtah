class StoreController < ApplicationController
  before_action :set_categories, only: [:edit, :new]

  def index
    @items = LineItem.all
  end

  def new
    @item = LineItem.new
  end

  def edit
    @item = LineItem.find(params[:id])
  end

  def update
    LineItem.find(params[:id]).update(item_params)
    redirect_to store_path
  end

  def create
    LineItem.create(item_params)
    redirect_to store_path
  end

  def add_to_cart
    
  end

  private

  def item_params
    params.require(:line_item).permit(:description, :title, :display, :cost, :category)
  end

  def set_categories
    @categories = ["Other", "Shoes", "Shirts", "Stuff"]
  end
end
