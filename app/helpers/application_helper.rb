module ApplicationHelper
  def getDate(str) #mm-dd-year
    return nil unless str.length == 10
    month, day, year = str.split('-').map(&:to_i)
    return nil unless year && month && day
    begin
      DateTime.new(year, month, day)
    rescue ArgumentError
      nil
    end
  end
end
