# 订单交易
class EventQueue::OrderError < EventQueue::Base
  
  routing_key "orders.error"

end