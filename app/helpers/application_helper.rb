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

  def render_modal(modal_id, additional_classes="", &block)
    render layout: "layouts/modal", locals: { modal_id: modal_id, additional_classes: additional_classes } { block.call }
  end

  def mobile_device?
    browser = Browser.new(request.user_agent)
    if browser.known?
      if browser.device.mobile? || !!(request.user_agent =~ /Mobile|webOS/)
        return true
      end
    end
    false
  end

  def humanize_seconds(ms)
    [[1000, :milliseconds], [60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
      if ms > 0
        ms, n = ms.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
  end

end
