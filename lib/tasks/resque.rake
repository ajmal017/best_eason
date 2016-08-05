require 'resque/tasks'
require 'resque/scheduler/tasks'
require File.expand_path("../../resque_timeout", __FILE__)

# 让rake resque能找到相应的类
task "resque:setup" => :environment do
  $LOAD_PATH.unshift "#{Rails.root}/app/models", "#{Rails.root}/app/workers"
end

namespace :resque do
  task :setup do
    require 'resque'
    require 'resque-scheduler'

    # 根据运行环境进行定制(产品环境下单独处理，避免对现有脚本的冲突)
    schedule_file = "#{Rails.root}/config/schedule#{'/' + Rails.env.to_s unless Rails.env.production?}.yml"
    Resque.schedule = YAML.load_file(schedule_file) if File.exists?(schedule_file)

    # 设置任务执行超时
    Resque::Timeout.timeout = 7200

    # fork之后重新连接redis
    Resque.after_fork do |job|
      Resque.redis.client.reconnect
      Redis::Objects.redis.client.reconnect
      $redis.client.reconnect
      $cache.cache.reconnect
    end
  end

  
end

