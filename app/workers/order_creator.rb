class OrderCreator
  @queue = :order_creator
  
  # Resque.enqueue(OrderCreator, user_id)
  def self.perform(user_id = nil)
    if user_id
      Order.create_orders(user_id)
      Rails.logger.info "=="*5 + "订单已完成" + "=="*5
    else
      Order.publish_to_ib
    end
  end
end