module ApplicationHelper
  def parse_date(str) #mm-dd-year
    return nil unless str
    month, day, year = str.first(10).split('-').map(&:to_i)
    return nil unless year && month && day
    begin
      Time.zone.local(year, month, day)
    rescue ArgumentError
      nil
    end
  end
end
