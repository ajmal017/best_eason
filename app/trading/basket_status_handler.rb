module Trading
  
  class OrderData
    include InitHelper
    
    def update_ib_order_id
      error? ? order_detail.to_error! : order_detail.try(:update_attributes, ib_order_id: self.order_id.to_i)
    end
    
    def error?
      error rescue nil
    end
    
    def order_detail
      ::OrderDetail.fetch_by(self.symbol, self.real_instance_id, self.real_order_id).first
    end
    
    def real_instance_id
      instance_id.split(":")[0] if instance_id
    end
    
    # 已经存在此方法了，只能另取
    def real_order_id
      instance_id.split(":")[1] if instance_id
    end
  end
  
  class BasketStatusHandler
    
    def initialize(msg)
      @basket_status = msg
    end
    
    def basket_id
      @basket_status["basketId"]
    end
    
    def orders
      case basket_order
      when Hash
        [OrderData.new(basket_order.merge(instance_id: basket_id))]
      when Array
        basket_order.inject([]) { |sum, order| sum << OrderData.new(order.merge(instance_id: basket_id)) }
      else
        []
      end
    end
    
    def basket_order
      @basket_status["order"]
    end
    
    def error
      @basket_status["error"]
    end
    
    def order_id
      basket_id.split(":")[1] if basket_id
    end
    
    def order
      @order || ( @order = ::Order.find_by(id: order_id) )
    end
    
    def expire_order
      order.expire! if order && order.may_expire?
    end
    
    def error_order!
      order.order_details.each { |od| od.to_error! if od.may_to_error? } if order
    end
    
    def update_ib_order_id
      orders.each { |order| order.update_ib_order_id }
    end
    
    def expired?
      error == "Expired"
    end
    
    def error?
      error.present?
    end
  
    def perform
      ActiveRecord::Base.transaction do
        if error?
          error_order!
        else
          update_ib_order_id
        end
      end
    end
    
  end
  
end