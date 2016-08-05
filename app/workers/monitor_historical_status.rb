class MonitorHistoricalStatus
  @queue = :monitor_historical_status
  
  UNSYNC = 0
  SYNCING = 1

  def self.perform
    syncing_length = $redis.llen('resque:queue:his_sync')
    status_key = 'sync_historical_status'
    
    if syncing_length >= 100
      $redis.set(status_key, SYNCING)  
      
      $monitor_logger.info("===正在同步===#{syncing_length}")
    elsif syncing_length.zero? && $redis.get(status_key).to_i == SYNCING
      $redis.set(status_key, UNSYNC)
      
      Resque.enqueue(CalculateBasketIndex)
      Resque.enqueue(KlineGenerate)
      
      $monitor_logger.info("===同步完成===")
    else
      $monitor_logger.info("不符合条件")
    end
  end
end
