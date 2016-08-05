# 订单交易
class EventQueue::OrderTrade < EventQueue::Base
  
  routing_key "orders.trade"

end