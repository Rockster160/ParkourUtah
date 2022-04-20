module ApplicationHelper

  def current_instructor?
    return false unless user_signed_in?

    current_user.instructor?
  end

  def current_admin?
    return false unless user_signed_in?

    current_user.admin?
  end

  def strip_phone_number(phone_number)
    stripped_number = phone_number.to_s.gsub(/[^0-9]/, "").last(10)
    return unless stripped_number.length == 10
    stripped_number
  end

  def format_phone_number(phone_number)
    stripped_number = strip_phone_number(phone_number)
    return unless stripped_number.try(:length) == 10
    "+1 (#{stripped_number[0..2]}) #{stripped_number[3..5]}-#{stripped_number[6..9]}"
  end

  def timeago(time, options = {})
    options[:class] ||= "timeago"
    simple_time = time.to_formatted_s(:simple)
    content_tag(:time, simple_time, options.merge(datetime: time.to_i, title: simple_time)) if time
  end

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
    render layout: "layouts/modal", locals: { modal_id: modal_id, additional_classes: additional_classes } do
      block.call
    end
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
    [[1000, :milliseconds], [60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map { |count, name|
      if ms > 0
        ms, n = ms.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
  end

end
