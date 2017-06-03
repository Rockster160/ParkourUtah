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
    keys = params[:how_many].join("").to_i.times.map { item.redemption_keys.create(expiry_date: params[:expiry_date]) }
    slack_message = "*#{item.title}*\nKeys expire: "
    if keys.first.try(:expiry_date)
      slack_message += "_#{keys.first.expiry_date}_"
    else
      slack_message += "_N/A_"
    end
    slack_message += "\n```#{keys.map {|key|key.key}.join("\n")}```"
    channel = Rails.env.production? ? '#admin' : '#slack-testing'
    SlackNotifier.notify(slack_message, channel)
    redirect_to redemption_keys_path, notice: "Got it! We'll post the keys to the #admin slack channel"
  end

  def destroy
    rkey = RedemptionKey.find(params[:id])

    if rkey.destroy
      redirect_to redemption_keys_path, notice: "That Redemption Key has been deleted and can no longer be used."
    else
      redirect_to redemption_keys_path, alert: "There was an error destroying that Key."
    end
  end

end
