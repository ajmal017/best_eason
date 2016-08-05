class ResetHaltedTradeTime
  @queue = :quote
  
  def self.perform
    BaseStock.cn.except_x.where(listed_state: BaseStock::LISTED_STATE[:abnormal]).each do |bs|
      HistoricalQuoteCn.reset_trade_time(bs.id)
    end
  end

end
