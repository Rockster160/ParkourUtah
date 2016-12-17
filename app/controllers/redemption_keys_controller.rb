class RedemptionKeysController < ApplicationController
  before_action :validate_admin, except: [ :redeem ]

  def index
    @keys = RedemptionKey.where(redeemed: false)
  end

  def new
    @hidden = LineItem.where(hidden: true)
  end

  def create
    item = LineItem.find(params[:line_item_id])
    keys = params[:how_many].to_i.times.map { item.redemption_keys.create.key }
    # TODO SLACK - post Item Title with list of generated keys
    redirect_to redemption_keys_path, notice: "Got it! We'll post the keys to the #admin slack channel"
  end

end
