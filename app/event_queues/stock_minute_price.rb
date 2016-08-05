class EventQueue::StockMinutePrice < EventQueue::Base
  routing_key "stocks.minute_price"
  #暂时未使用
end