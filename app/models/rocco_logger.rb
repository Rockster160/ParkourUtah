# == Schema Information
#
# Table name: rocco_loggers
#
#  id         :integer          not null, primary key
#  logs       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RoccoLogger < ActiveRecord::Base

  def self.add(str, date=Time.now)
    logger = RoccoLogger.by_date(date)
    logger.update(logs: "#{logger.logs}\n#{Time.now.strftime('%l:%M:%S %p')} #{str}")
  end

  def self.by_date(date=Time.now)
    logger = RoccoLogger.all.select {|rl|rl.created_at.to_date == date.to_date}.last
    logger ||= RoccoLogger.create
  end
end
