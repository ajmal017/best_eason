# bundle exec rake resque:work --trace QUEUE=* BACKGROUND=yes
# bundle exec rake resque:scheduler --trace BACKGROUND=yes
# 开启 bundle exec resque-web config/resque_web.rb
# 关闭 bundle exec resque-web -K
require 'resque'
require 'resque-dynamic-queues-server' 

Resque.redis = YAML.load_file("config/redis.yml")[ENV['RAILS_ENV']] || "localhost:6379"

# This will make the tabs show up.
require 'resque-scheduler'
require 'resque/scheduler/server'

require 'yaml'
Resque.schedule = YAML.load_file("config/schedule.yml")