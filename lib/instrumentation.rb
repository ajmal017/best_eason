require 'instrumentation/rails'
require 'instrumentation/redis'
require 'instrumentation/api'
require 'instrumentation/mongo'
require 'elasticsearch_ext'
require 'instrumentation/elasticsearch'

ActiveSupport.on_load(:action_controller) do
  include Victor::Instrumentation::Mongo::ControllerRuntime
  include Victor::Instrumentation::Redis::ControllerRuntime
  include Victor::Instrumentation::Api::ControllerRuntime
end
