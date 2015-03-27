module CalendarHelper
  def calendar(date = Date.today, &block)
    Calendar.new(self, date, block).table
  end

  def mobile_calendar(date = Date.today, &block)
    MobileCalendar.new(self, date, block).table
  end
end
