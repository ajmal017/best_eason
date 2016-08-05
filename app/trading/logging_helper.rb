module Trading
  
  module LoggingHelper
    
    def logging_and_notify(payload, exception, type, message, print_backtrace)
      logging(payload, exception, type, message, print_backtrace)
      notify(payload, exception)
    end

    def logging(payload, exception, type, message, print_backtrace)
      payload = exception.blank? ? "PROCESS SUCCESS <#{payload}>" : "PROCESS ERROR <#{payload}>"
      backtrace = print_backtrace && exception.present? ? "BACKTRACE <#{exception.backtrace.join("\n")}>" : ""
      message = exception.present? ? "MESSAGE #{message.to_s}" + " <#{exception.message}>" : "MESSAGE #{message.to_s}"
      info = payload + "\n" + message + "\n" + backtrace
      type == "ERROR" ? (logger.error info) : (logger.warn info)
    end

    def notify(payload, exception)
      ExceptionNotifier.notify_exception(exception, :data => {:payload => payload}) rescue nil
    end
    
  end
  
end
