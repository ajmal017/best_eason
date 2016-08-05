module Trading
  
  class HeartbeatStatusHandler
    
    include InitHelper
    
    def perform
      $redis.del("pms_cts_heartbeat")
    end
  end
  
end
