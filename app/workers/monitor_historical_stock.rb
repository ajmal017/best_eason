class MonitorHistoricalStock
  @queue = :monitor_historical_stock

  def self.perform(start_id, sign)
    if start_id < 0
      sign = SecureRandom.hex(8)

      min_id = BaseStock.minimum(:id)
      max_id = BaseStock.maximum(:id)
      (min_id..max_id).step(Yahoo::HistoricalChange::NUM_PER_MONITOR).each do |x|
        Resque.enqueue(MonitorHistoricalStock, x, sign)
      end
    else
      Yahoo::HistoricalChange.new(start_id, sign).monitor
    end
  end
end
