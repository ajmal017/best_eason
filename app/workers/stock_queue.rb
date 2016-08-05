class StockQueue
  @queue = :stock_queue
  
  def self.perform(stock_id)
    stock = BaseStock.find(stock_id)
    return false unless stock
    date = stock.market_area == :us ? (Date.today-1) : Date.today
    stock.cal_stock_returns(date)
  end
end