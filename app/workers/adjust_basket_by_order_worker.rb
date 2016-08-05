class AdjustBasketByOrderWorker
  @queue = :adjust_basket_by_order_worker
  
  def self.perform(order_id)
    AdjustBasketByOrder.new(order_id).call
  end

end
