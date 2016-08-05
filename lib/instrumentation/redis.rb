module Victor
  module Instrumentation
    module Redis
      module ControllerRuntime
        extend ActiveSupport::Concern

        protected

        attr_internal :redis_runtime

        def process_action(action, *args)
          LogSubscriber.reset_runtime
          super
        end

        def cleanup_view_runtime
          redis_rt_before_render = LogSubscriber.reset_runtime
          runtime = super
          redis_rt_after_render = LogSubscriber.reset_runtime
          self.redis_runtime = redis_rt_before_render + redis_rt_after_render
          runtime - redis_rt_after_render
        end

        def append_info_to_payload(payload)
          super
          payload[:redis_runtime] = redis_runtime
        end

        module ClassMethods
          def log_process_action(payload)
            messages, redis_runtime = super, payload[:redis_runtime]
            if redis_runtime
              runtime = redis_runtime.to_f
              color = if runtime < 10
                        "\e[32m"
                      elsif runtime < 50
                        "\e[33m"
                      else
                        "\e[31m"
                      end
              messages << ("Redis: \e[1m#{color}%.1f\e[0m ms" % runtime)
            end
            messages
          end
        end
      end

      class LogSubscriber < ActiveSupport::LogSubscriber
        RUNTIME_KEY = 'victor_redis_runtime'

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

        def redis(event)
          self.class.runtime += event.duration
        end
      end
    end
  end
end

Victor::Instrumentation::Redis::LogSubscriber.attach_to :victor

class Redis::Client
  def process_with_instrumentation(*args, &block)
    ActiveSupport::Notifications.instrumenter.instrument "redis.victor", :name => :process do
      process_without_instrumentation(*args, &block)
    end
  end
  alias_method_chain :process, :instrumentation
end
