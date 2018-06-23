class CompetitionChannel < ApplicationCable::Channel

  def subscribed
    stream_from "competition_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end
