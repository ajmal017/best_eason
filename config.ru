# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'resque/server'
require 'resque-dynamic-queues-server' 
require 'resque/scheduler/server'

if defined?(Unicorn)
  require 'unicorn/oob_gc'
#  require 'unicorn/worker_killer'
  
#  use Unicorn::OobGC, 10 
#  use Unicorn::WorkerKiller::MaxRequests, 2048, 3072
#  use Unicorn::WorkerKiller::Oom, (300*(1024**2)), (400*(1024**2)) unless Rails.env == "development"
end

# You need to manually start the agent
NewRelic::Agent.manual_start if defined?(NewRelic)

run Rack::URLMap.new \
  "/"       => Rails.application,
  "/resque" => Resque::Server.new
