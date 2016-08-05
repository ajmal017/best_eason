module Trading
  
  class OrderStatusConsumer
    
    include Sneakers::Worker
    from_queue 'com.caishuo.orderstatus', :threads => 1, :prefetch => 1, :exchange_arguments => {
                              "alternate-exchange" => "caishuox.unroutable"
                            },
                            :queue_arguments => {
                              "x-dead-letter-exchange" => "caishuox.deadletter",
                              "x-dead-letter-routing-key" => "com.caishuo.orderstatus.deadletter"
                            }
    MAX_ATTEMPTS = 3
  
    RETRY_INTERVAL = 0.5                          
  
    include LoggingHelper
    include AckHelper
    
    def work(msg)
      msg_origin = msg
      msg = msg.to_h
      num_attempts = 0
      begin
        num_attempts += 1
        if msg.keys.first == "basket"
          order = Order.find_by(id: order_id(msg["basket"]["basketId"]))
          if order && order.may_confirm?
            order.confirm!
            logging("DONE <#{msg_origin}>", nil, "WARN", nil, false)
            success!
          else
            logging("DROPED <#{msg_origin}>", nil, "WARN", nil, false)
            drop!
          end
        else
          msg.keys.first == "requestFundamentals" ? $fundatmental_logger.info("DROPED <#{msg_origin}>") : logging("DROPED <#{msg_origin}>", nil, "WARN", nil, false)
          drop!
        end
      rescue ActiveRecord::RecordNotFound => e
        logging(msg_origin, e, "ERROR", "找不到对应的记录", false)
        drop!
      rescue Exception => e
        if e.message =~ /execution expired/i
          if num_attempts <= MAX_ATTEMPTS
            ActiveRecord::Base.connection.reconnect!
            logging_and_notify(msg_origin, e, "ERROR", "job timeout reconnect database", true)
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
      end
    end
  
    def order_id(basket_id)
      basket_id.split(":")[1] if basket_id
    end
    
  end
  
end