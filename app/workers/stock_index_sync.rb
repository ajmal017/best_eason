class StockIndexSync
  @queue = :stock_index

  def self.perform
    Yahoo::StockIndex::Base.sync
  end
end
