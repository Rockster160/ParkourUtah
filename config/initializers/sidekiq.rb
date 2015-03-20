require 'sidekiq/web'

config = {
  host: Redis.current.client.host,
  port: Redis.current.client.port,
  password: Redis.current.client.password,
  db: (!!defined?(REDIS_CONFIG) ? REDIS_CONFIG[:db_worker] : Redis.current.client.db),
  namespace: "sidekiq"
}

Sidekiq.configure_server { |c| c.redis = config }
Sidekiq.configure_client { |c| c.redis = config }
