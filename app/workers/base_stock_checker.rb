class BaseStockChecker
  @queue = :base_stock_checker

  def self.perform
    BaseStock.qualify
  end
end
