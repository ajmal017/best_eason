require 'errors'
module Trading
  
  class PmsConsumer
    include Sneakers::Worker
 
    from_queue 'com.caishuo.pms', :threads => 1, :prefetch => 1, :exchange_arguments => {
                              "alternate-exchange" => "caishuox.unroutable"
                            },
                            :queue_arguments => {
                              "x-dead-letter-exchange" => "caishuox.deadletter",
                              "x-dead-letter-routing-key" => "com.caishuo.pms.deadletter"
                            }

    PROCESSED_HANDLERS = ["heartbeatStatus", "position", "ReportFinancialStatements", "accountDownloadEnd", "basketStatus", "orderStatus", "updatePortfolio", "accountSummary", "updateAccountValue", "execDetails", "error", "ReportSnapshot"]

    MAX_ATTEMPTS = 3
  
    RETRY_INTERVAL = 0.5
    
    include LoggingHelper
    
    include AckHelper
    
    
    def work(msg)
      msg_origin = msg
      msg = msg.to_h
      num_attempts = 0
      if PROCESSED_HANDLERS.include?(msg.keys.first)
        begin
          num_attempts += 1
          if ["ReportSnapshot","ReportFinancialStatements"].include?(msg.keys.first)
            ("Trading::" + msg.keys.first.camelize + "Handler").constantize.new(msg_origin).perform
          else
            ("Trading::" + msg.keys.first.camelize + "Handler").constantize.new(msg[msg.keys.first]).perform
          end
        rescue ActiveRecord::RecordNotFound, ::Trading::BindingUserError => e
          logging(msg_origin, e, "ERROR", "找不到对应的记录", false)
          drop!
        rescue Exception => e
          if e.message =~ /execution expired/i
            if num_attempts <= MAX_ATTEMPTS
              logging_and_notify(msg_origin, e, "ERROR", "job timeout reconnect database", true)
              ActiveRecord::Base.connection.reconnect!
              sleep RETRY_INTERVAL
              retry
            else
              logging_and_notify(msg_origin, e, "ERROR", "执行超时", true)
              requeue!
            end
          else
            logging_and_notify(msg_origin, e, "ERROR", "未知异常", true)
            to_dead_letter!
          end
        else
          ["ReportSnapshot","ReportFinancialStatements"].include?(msg.keys.first) ? $fundatmental_logger.info("DONE <#{msg_origin}>") : logging("DONE <#{msg_origin}>", nil, "WARN", nil, false)
          success!
        end
      else
        logging("DROPED <#{msg_origin}>", nil, "WARN", nil, false)
        drop!
      end
    end
    
  end
  
end
