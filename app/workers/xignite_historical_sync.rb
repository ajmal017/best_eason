class XigniteHistoricalSync
  @queue = :xignite_historical

  def self.perform(symbol, exchange = 'sehk')
    if symbol.blank?
      symbols = ["^GSPC", "^IXIC", "^HSI"]
      BaseStock.select(:xignite_symbol).send(exchange.to_sym).trading_normal.pluck(:xignite_symbol).push(symbols).flatten.each do |xignite_symbol|
        Resque.enqueue(XigniteHistoricalSync, xignite_symbol)
      end
    else
      Xignite::Historical::Base.new(symbol).sync
    end
  end
end
