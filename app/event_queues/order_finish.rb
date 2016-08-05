# 订单完成
class EventQueue::OrderFinish < EventQueue::Base
  
  routing_key "orders.finish"

end