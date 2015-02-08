class Event < ActiveRecord::Base
  def host
    User.find(host_id)
  end
end
