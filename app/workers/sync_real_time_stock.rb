class SyncRealTimeStock
  @queue = :rt_sync

  def self.perform(symbols='')
    if symbols.blank?
      special_symbols = ['^IXIC', '^GSPC', 'HKD=X', 'CNY=X', 'HKDUSD=X', 'CNYUSD=X', 'HKDCNY=X', 'CNYHKD=X']
      BaseStock.select(:ticker).latest.pluck(:ticker).push(special_symbols).in_groups_of(Yahoo::RealTime::Base::NUM_PER_SYNC).each do |symbols|
        Resque.enqueue(SyncRealTimeStock, symbols.compact.join(','))
      end
    else
      Yahoo::RealTime::YQL.new(symbols.to_s.split(',')).sync
    end
  end

end
