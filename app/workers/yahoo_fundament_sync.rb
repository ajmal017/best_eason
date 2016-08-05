class YahooFundamentSync
  @queue = :fundament_sync

  def self.perform(symbols = '')
    if symbols.blank?
      BaseStock.trading_normal.select(:ticker).pluck(:ticker).in_groups_of(300).each do |tickers|
        Resque::enqueue(YahooFundamentSync, tickers.compact.join(','))
      end
    else
      Yahoo::Fundament::Base.new(symbols.to_s.split(',')).sync
    end
  end
end
