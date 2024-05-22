# Override default from PrettyLogger
::PrettyLogger::RequestLogger.class_eval do
  def pretty_user
    return colorize(:grey, "[?]") unless current_user.present?

    case current_user.id
    when 4 then colorize(:rocco, "[Me]")
    when 2 then colorize(:maroon, "[Ryan]")
    when 1022 then colorize(:pink, "[Sarah]")
    when 33529 then colorize(:gold, "[Chris]")
    else colorize(:olive, "[#{current_user.id}]")
    end
  end
end
