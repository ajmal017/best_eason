module Victor
  module Instrumentation
    module Api
      module ControllerRuntime
        extend ActiveSupport::Concern

        protected

        attr_internal :api_runtime

        def process_action(action, *args)
          LogSubscriber.reset_runtime
          super
        end

        def cleanup_view_runtime
          api_rt_before_render = LogSubscriber.reset_runtime
          runtime = super
          api_rt_after_render = LogSubscriber.reset_runtime
          self.api_runtime = api_rt_before_render + api_rt_after_render
          runtime - api_rt_after_render
        end

        def append_info_to_payload(payload)
          super
          payload[:api_runtime] = api_runtime
        end

        module ClassMethods
          def log_process_action(payload)
            messages, api_runtime = super, payload[:api_runtime]
            if api_runtime
              runtime = api_runtime.to_f
              color = if runtime < 100
                        "\e[32m"
                      elsif runtime < 200
                        "\e[33m"
                      else
                        "\e[31m"
                      end
              messages << ("Api: \e[1m#{color}%.1f\e[0m ms" % runtime)
            end
            messages
          end
        end
      end

      class LogSubscriber < ActiveSupport::LogSubscriber
        RUNTIME_KEY = 'victor_api_runtime'

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

        def api(event)
          self.class.runtime += event.duration
        end
      end
    end
  end
end

Victor::Instrumentation::Api::LogSubscriber.attach_to :victor

class Typhoeus::Hydra
  def run_with_instrumentation(*args, &block)
    ActiveSupport::Notifications.instrumenter.instrument "api.victor", :name => :run do
      run_without_instrumentation(*args, &block)
    end
  end
  alias_method_chain :run, :instrumentation
end
