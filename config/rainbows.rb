rails_env = ENV['RAILS_ENV'] || 'production'
APP_PATH = "/caishuo/web"

worker_processes 4 # assuming four CPU cores
listen "#{APP_PATH}/shared/tmp/sockets/.unicorn.sock", :backlog => 2048
#listen 8080, :tcp_nopush => false, :tcp_nodelay => true
listen 3005, :tcp_nopush => false, :tcp_nodelay => true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# feel free to point this anywhere accessible on the filesystem
pid "#{APP_PATH}/shared/tmp/pids/unicorn.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path "#{APP_PATH}/shared/log/unicorn.stderr.log"
stdout_path "#{APP_PATH}/shared/log/unicorn.stdout.log"

# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

Rainbows! do
  use :FiberSpawn
  worker_connections 1000
end
