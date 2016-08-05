APP_ROOT = '/caishuo/web/current'
directory APP_ROOT
pidfile "#{APP_ROOT}/tmp/pids/puma.pid"
state_path "#{APP_ROOT}/tmp/pids/puma.state"

bind 'tcp://0.0.0.0:3000'
bind "unix://#{APP_ROOT}/tmp/sockets/puma.sock"

activate_control_app "tcp://0.0.0.0:3010", { no_token: true }

worker_timeout 30

daemonize true
threads 16,16
workers 4
preload_app!


GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end


  Rails.cache.reconnect
  Redis::Objects.redis.client.reconnect
  $redis.client.reconnect
  $cache.cache.reconnect
  Publisher.client.reconnect
  # GC::Profiler.enable if environment == 'staging' or environment == 'production'
  sleep 5



end
