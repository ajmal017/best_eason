module OrderCreateTester
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    
    def create_orders(user_id)
      create_hk_orders(user_id)
      create_us_orders(user_id)
    end
    
    def create_hk_orders(user_id)
      orders = []
      (hk_orders(user_id)).each do |order|
        o = OrderBuy.create({ basket_id: nil, user_id: user_id }.merge(order))
        orders << o.id
      end
      $redis.set("hk_order_ids", orders.join(","))
    end
    
    def create_us_orders(user_id)
      orders = []
      (us_orders(user_id)).each do |order|
        o = OrderBuy.create({ basket_id: nil, user_id: user_id }.merge(order))
        orders << o.id
      end
      $redis.set("us_order_ids", orders.join(","))
    end
  
    def hk_orders(user_id)
      size = hk_stock_ids(user_id).size
      orders = []
      hk_stock_ids(user_id).in_groups_of((size/10 + 10), false).each do |base_stocks|
        order_details_attributes = {}
        base_stocks.each_with_index do |bs, index|
          order_details_attributes.merge!( index => { est_shares: bs.est_shares, base_stock_id: bs.id } )
        end
        orders << { order_details_attributes: order_details_attributes }
      end
      orders
    end
  
    def us_orders(user_id)
      size = us_stock_ids(user_id).size
      orders = []
      us_stock_ids(user_id).in_groups_of((size/10 + 10), false).each do |base_stocks|
        order_details_attributes = {}
        base_stocks.each_with_index do |bs, index|
          order_details_attributes.merge!( index => { est_shares: bs.est_shares, base_stock_id: bs.id } )
        end
        orders << { order_details_attributes: order_details_attributes }
      end
      orders
    end
  
    def us_stock_ids(user_id)
      @us_ids || (@us_ids = BaseStock.normal.where(exchange: ['NASDAQ', 'NYSE']) - BaseStock.normal.where(exchange: ['NASDAQ', 'NYSE']).joins(:positions).where("positions.user_id = ? and positions.shares <> ?", user_id, 0).uniq)
    end
  
    def hk_stock_ids(user_id)
      @hk_ids || (@hk_ids = BaseStock.normal.where(exchange: 'SEHK') - BaseStock.normal.where(exchange: 'SEHK').joins(:positions).where("positions.user_id = ? and positions.shares <> ?", user_id, 0).uniq)
    end
  
    def publish_to_ib
      publish_hk_order if Exchange::Hk.instance.trading?
      publish_us_order if Exchange::Us.instance.trading?
    end
    
    def publish_hk_order
      if (order_ids = $redis.get("hk_order_ids")).present?
        ids = order_ids.split(",")
        id = ids.pop
        OrderStatusPublisher.publish(Order.find(id).to_xml) if id.present?
        $redis.set("hk_order_ids", ids.join(","))
        Rails.logger.info "=="*5 + "订单#{id}已发送" + "=="*5
      else
        Rails.logger.info "=="*5 + "无订单id" + "=="*5
      end
    end
    
    def publish_us_order
      if (order_ids = $redis.get("us_order_ids")).present?
        ids = order_ids.split(",")
        id = ids.pop
        OrderStatusPublisher.publish(Order.find(id).to_xml) if id.present?
        $redis.set("us_order_ids", ids.join(","))
        Rails.logger.info "=="*5 + "订单#{id}已发送" + "=="*5
      else
        Rails.logger.info "=="*5 + "无订单id" + "=="*5
      end
    end
    
  end #ClassMethods
end
