module Trading
  
  class DeadletterConsumer
    include Sneakers::Worker
 
    from_queue 'com.caishuo.pms.deadletter', :threads => 1, :prefetch => 1,:exchange_arguments => {
                              "alternate-exchange" => "caishuox.unroutable"
                            }


    include LoggingHelper
    
    include AckHelper
    
    
    def work(msg)
      $pms_deadletter_logger.info(msg)
      drop!
    end
    
  end
  
end

