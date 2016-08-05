class StockCapitalization
  @queue = :stock_capitalization

  def self.perform
    BaseStock.find_in_batches(batch_size: 2000) do |base_stocks|
      stocks = base_stocks.map { |bs| BaseStock.new(id: bs.id, market_value: bs.market_value_with_usd) }
      BaseStock.import_market_value(stocks)
    end
  end
end
