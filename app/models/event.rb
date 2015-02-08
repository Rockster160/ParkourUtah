class Event < ActiveRecord::Base
  def host_by_id
    User.find(host)
  end
end
