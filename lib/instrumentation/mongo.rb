module Victor
  module Instrumentation
    module Mongo
      module ControllerRuntime
        extend ActiveSupport::Concern
        
        protected
    
        attr_internal :mongo_runtime
    
        def process_action(action, *args)
          LogSubscriber.reset_runtime
          super
        end
    
        def cleanup_view_runtime
          mongo_rt_before_render = LogSubscriber.reset_runtime
          runtime = super
          mongo_rt_after_render = LogSubscriber.reset_runtime
          self.mongo_runtime = mongo_rt_before_render + mongo_rt_after_render
          runtime - mongo_rt_after_render
        end
    
        def append_info_to_payload(payload)
          super
          payload[:mongo_runtime] = mongo_runtime
        end
    
        module ClassMethods
          def log_process_action(payload)
            messages, mongo_runtime = super, payload[:mongo_runtime]
            if mongo_runtime
              runtime = mongo_runtime.to_f
              color = if runtime < 100
                "\e[32m"
              elsif runtime < 200
                "\e[33m"
              else
                "\e[31m"
              end
              messages << ("Mongo: \e[1m#{color}%.1f\e[0m ms" % runtime)
            end
            messages
          end
        end
      end
    
      class LogSubscriber < ActiveSupport::LogSubscriber
        RUNTIME_KEY = 'victor_mongo_runtime'
      
        def self.runtime=(value)
          Thread.current[RUNTIME_KEY] = value
        end
      
        def self.runtime
          Thread.current[RUNTIME_KEY] ||= 0
        end
      
        def self.reset_runtime
          rt, self.runtime = runtime, 0
          rt
        end
      
        def mongo(event)
          self.class.runtime += event.duration
        end
      end
    end
  end
end

Victor::Instrumentation::Mongo::LogSubscriber.attach_to :victor

class Moped::Connection
  def read_with_instrumentation(*args, &block)
    ActiveSupport::Notifications.instrumenter.instrument "mongo.victor", :name => :read do
      read_without_instrumentation(*args, &block)
    end
  end
  alias_method_chain :read, :instrumentation

  def write_with_instrumentation(*args, &block)
    ActiveSupport::Notifications.instrumenter.instrument "mongo.victor", :name => :write do
      write_without_instrumentation(*args, &block)
    end
  end
  alias_method_chain :write, :instrumentation
end
