module ActionController::Instrumentation
  private
  module ClassMethods
    def log_process_action(payload) #:nodoc:
      messages, view_runtime = [], payload[:view_runtime]
      if view_runtime
        runtime = view_runtime.to_f
        color = if runtime < 200
                  "\e[32m"
                elsif runtime < 500
                  "\e[33m"
                else
                  "\e[31m"
                end
        messages << ("Views: \e[1m#{color}%.1f\e[0m ms" % runtime)
      end
      messages
    end
  end
end

module ActiveRecord::Railties::ControllerRuntime
  protected
  module ClassMethods
    def log_process_action(payload)
      messages, db_runtime = super, payload[:db_runtime]
      if db_runtime
        runtime = db_runtime.to_f
        color = if runtime < 100
                  "\e[32m"
                elsif runtime < 200
                  "\e[33m"
                else
                  "\e[31m"
                end
        messages << ("Mysql: \e[1m#{color}%.1f\e[0m ms" % runtime)
      end
      messages
    end
  end
end
