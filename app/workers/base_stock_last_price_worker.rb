class BaseStockLastPriceWorker
  @queue = :base_stock

  def self.perform
    #BaseStock.sync_last_price
  end
end
