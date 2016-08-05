class SyncHistoricalStock
  @queue = :his_sync

  def self.perform(stock_ids, exchange = 'sehk')
    if stock_ids.blank?
      symbols = ["^GSPC", "^IXIC", "HKD=X", "CNY=X", "^HSI"]
      special_ids = BaseStock.where(:symbol => symbols).map(&:id)
      BaseStock.select(:id).send(exchange.to_sym).latest.pluck(:id).push(special_ids).in_groups_of(Yahoo::Historical::Base::NUM_PER_SYNC).each do |ids|
        Resque.enqueue(SyncHistoricalStock, ids.compact.join(','))
      end
    else
      Yahoo::Historical::Base.new(stock_ids.to_s.split(',')).sync
    end
  end
end
