class Subscription < ActiveRecord::Base
  # t.integer "user_id"
  # t.integer "event_id"

  belongs_to :event
  belongs_to :user

  def user_phone_number
    User.find(user_id).phone_number
    # TODO What happens after a subscription is made and a user deletes/changes their phone?
  end
end
