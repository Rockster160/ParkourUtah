directory '/home/deploy/parkourutah/current'
port ENV.fetch("PORT") { 7545 }
environment 'production'
bind 'unix:///home/deploy/parkourutah/shared/sockets/puma.sock'
stdout_redirect '/home/deploy/parkourutah/shared/log/puma.stdout.log',
                '/home/deploy/parkourutah/shared/log/puma.stderr.log', true
threads 1, 5
workers 2
preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
