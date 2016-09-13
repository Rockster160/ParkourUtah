class CustomLogger
  class << self

    def log_request(request, user=nil, cart_id)
      filtered_params = filter_hash(request.env["action_dispatch.request.parameters"])
      log("#{request.env["REQUEST_METHOD"]} - #{request.env['REQUEST_PATH']} #{filtered_params}", user, cart_id)
    end

    def log(message, user=nil, cart_id)
      display_name = user.present? ? "#{user.try(:id)}: #{user.try(:email)}" : ''
      formatted_time = (DateTime.current - 6.hours).strftime('%b %d, %Y %H:%M:%S.%L')
      File.open("log/custom_logger.txt", "a+"){|f| f << "\n#{formatted_time} - #{message}\n#{display_name}\nCart: #{cart_id}" }
    end

    def filter_hash(hash)
      new_hash = hash.deep_dup
      dangerous_keys = new_hash.keys.grep(/password/)
      dangerous_keys.each { |k| new_hash[k].is_a?(String) ? new_hash[k] = '[[FILTERED PASSWORD]]' : nil }
      new_hash.each do |hash_key, hash_val|
        if hash_val.is_a?(Hash)
          new_hash[hash_key] = filter_hash(new_hash[hash_key])
        end
      end
      new_hash
    end

  end
end
