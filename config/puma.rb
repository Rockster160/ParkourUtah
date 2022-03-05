# Workers for clustered mode - default 2
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Thread count - default 5
threads_count_min = ENV.fetch("RAILS_MIN_THREADS") { 1 }.to_i
threads_count_max = ENV.fetch("RAILS_MAX_THREADS") { 10 }.to_i
threads threads_count_min, threads_count_max

# Port - default 3000
port ENV.fetch("PORT") { 7545 }

# Environment - default 'development'
environment ENV.fetch("RAILS_ENV") { "development" }

# When workers are specified, the app needs to be preloaded
# preload_app!

# When workers are specified, the database connection must be established
# on each worker's boot
# on_worker_boot do
#   ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
# end
