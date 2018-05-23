namespace :db_to_json do
  desc "Exports the Database into a JSON file"
  task export: :environment do |t, args|
    file = ENV["FILENAME"] || "db_dump-#{DateTime.current.strftime("%m-%d-%y")}.json"
    puts "Outputting to: #{file}".colorize(:yellow)

    File.open(file, "w+") do |f|
      full_export = {}
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.each do |klass|
        next puts "Not DB backed: #{klass}".colorize(:red) unless klass.try(:table_name).present?
        next puts "Skipping: #{klass}".colorize(:yellow) if klass.to_s.in?(["AwsLogger"])
        begin
          puts "#{klass}: #{klass.count}".colorize(:green)
          full_export[klass.to_s] = klass.all.map do |instance|
            instance.attributes
          end
        rescue => e
          puts "#{e.class}: #{(e.try(:message) || e.try(:body) || e).to_s.first(50)}".colorize(:red)
        end
      end
      f.puts full_export.to_json
    end
    puts "Successfully exported to: #{file}".colorize(:yellow)
  end
end

# rails db_to_json:export; mv db_dump-04-21-18.json ../db_dump-04-21-18.json
# raw = File.read("../db_dump-04-21-18.json"); json = JSON.parse(raw) rescue nil; json.try(:keys)
# head -c 5000 ../db_dump-04-21-18.json
