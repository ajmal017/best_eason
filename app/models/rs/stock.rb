class Rs::Stock < Redis::HashKey

  REDIS_NAMESPACE = "realtime:"

  def self.find(base_stock_id)
    new(base_stock_id)
  end

  def initialize(base_stock_id)
    super(redis_key(base_stock_id))
  end

  def redis_key(base_stock_id)
    "#{REDIS_NAMESPACE}#{base_stock_id}"
  end
  
  # cutoff 每日涨跌
  def cutoff_price_changed
    return 0 unless local_date == cutoff_today
    
    price_changed
  end

  def previous_close
    price = self.get("previous_close").to_f
    price > 0 ? price : realtime_price
  end

  def price_changed
    self.get("change_from_previous_close").to_f
  end

  def realtime_price
    self.get("last").to_f rescue 0
  end

  def local_date
    Time.parse(self.get("trade_time")).to_date
  rescue 
    nil
  end

  def market
    self.get("market")
  end

  # currency_by_market
  def currency
    ::MD::RS::Stock::CURRENCY_MAPPINGS[market.try(:to_sym)]
  end

  def cutoff_today
    Time.now.hour >= 9 ? Date.today : Date.yesterday
  end

  def percent_change_from_previous_close
    self.get("percent_change_from_previous_close").to_f.round(2) rescue 0
  end
  
  alias_method :change_percent, :percent_change_from_previous_close

end
