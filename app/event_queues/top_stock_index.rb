# 交易时间实时更新三大股指
class EventQueue::TopStockIndex < EventQueue::Base
  
  routing_key "stock_indexes.update"


  def self.publish(message, opts={})
    return if message.blank?
    markets = Exchange::Util.get_trading_markets
    return if markets.blank?
    message = message.slice(*markets)
    
    super(message, opts)
  end


end