module ExceptionNotifier
  class CustomNotifier

    def initialize(options)
    end

    def call(exception, options={})
      exception_name = "#{exception.class.to_s =~ /^[aeiou]/i ? 'An' : 'A'} `#{exception.class.to_s}`"

      if options[:env].nil?
        text = "#{exception_name} occurred in background\n"
      else
        env = options[:env]
        data = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
        kontroller = env['action_controller.instance']
        request = env['action_dispatch.request']
        if data[:current_user]
          text = "*#{data[:current_user].try(:username)}* experienced #{exception_name} while `#{env['REQUEST_METHOD']} <#{env['REQUEST_URI']}>`"
        else
          text = "#{exception_name} occurred while `#{env['REQUEST_METHOD']} <#{env['REQUEST_URI']}>`"
        end
        text += " was processed by `#{kontroller.controller_name}##{kontroller.action_name}`" if kontroller
        text += "\n"
        params = data[:params] || request&.params
        if params
          params = params.permit!.to_h if params.is_a?(::ActionController::Parameters)
          begin
            text += "```\n#{JSON.pretty_generate(params)}\n```"
          rescue StandardError
            str = "#{params}".truncate(2000)
            text += "```\n#{str}\n```"
          end
          text += "\n"
        end
      end

      clean_message = exception.message.gsub("`", "'")
      fields = [{ title: 'Exception', value: clean_message }]

      if exception.backtrace
        fields.push({ title: 'Focused Backtrace', value: exception.backtrace.map { |l|
          l.include?("/app/") ? l.gsub("`", "'").gsub(/^.*\/app\//, "") : nil
        }.compact.join("\n") })
      end

      exception_message = fields.map { |h| "*#{h[:title]}*\n#{h[:value]}" }.join("\n\n")
      attchs = [color: 'danger', text: exception_message, mrkdwn_in: %w(text fields)]

      environ = Rails.env.production? ? '' : " [#{Rails.env.upcase}]"
      ::SlackNotifier.notify(text, '#server-errors', "PKUT#{environ}", ':pkut:', attchs)
    end

  end
end
