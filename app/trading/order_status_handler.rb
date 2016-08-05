module Trading
  
  class OrderStatusHandler
    extend Forwardable
    
    PROCESSED_STATUS = ["Submitted", "Filled", "Cancelled", "Inactive", "ApiCancelled", "Rejected"]
    
    def_delegators :@order_detail, :previous_total_filled, :previous_total_cost, :completed?, :current_basket_id
    
    # 引入module，为当前类添加如下实例方法 basketId orderId status filled remaining avgFillPrice
    include InitHelper
    
    def initialize(options)
      super(options)
      @stock = ::BaseStock.find_by!(ib_symbol: symbol)
      @order_detail = ::OrderDetail.find_by!(instance_id: instance_id, order_id: real_order_id, base_stock_id: @stock.id)
      @this_time_cost = (filled.to_i * avg_fill_price.to_d) - previous_total_cost
      $pms_logger.info("OrderStatus: 本次价值#{@this_time_cost}") if Setting.pms_logger
      @this_time_filled = already_filled - previous_total_filled
      $pms_logger.info("OrderStatus: 本次完成#{@this_time_filled}") if Setting.pms_logger
    end
    
    def perform
      if PROCESSED_STATUS.include?(status)
        $pms_logger.info("OrderStatus: #{basket_id},#{symbol},#{status},#{filled},#{avg_fill_price},#{side}")  if Setting.pms_logger
        update_shares_and_avg_price
        create_order_log
      end
    end
    
    private
    def position
      @position ||= ::Position.find_or_create_by(instance_id: instance_id, base_stock_id: @stock.id, trading_account_id: @order_detail.trading_account_id)
      @position.copy_attrs(attrs)
      @position
    end
    
    def update_shares_and_avg_price
      ActiveRecord::Base.transaction do
        self.send("#{status.underscore}_perform")
      end
    end
    
    def rejected_perform
      @order_detail.reject! if @order_detail.may_reject?
    end
    
    def api_cancelled_perform
      @order_detail.api_cancell! if @order_detail.may_api_cancell?
    end

    def inactive_perform
      @order_detail.inactivate! if @order_detail.may_inactivate?
    end

    def submitted_perform
      if @order_detail.may_submit?
        @order_detail.submit(nil, filled, avg_fill_price) 
        update_position
      end
    end
    
    def filled_perform
      if @order_detail.may_fill?
        @order_detail.fill(nil, filled, avg_fill_price) 
        update_position
      end
    end
    
    def cancelled_perform
      if already_filled == 0
        if @order_detail.may_cancel?
          @order_detail.cancel(nil, filled, avg_fill_price)
          update_position
        end
      else
        if @order_detail.may_partial_fill?
          @order_detail.partial_fill(nil, filled, avg_fill_price)
          update_position
        end
      end
    end
    
    def update_position
      position.update_shares_and_avg_price(side, @this_time_filled, @this_time_cost)
      update_pending_shares if side == "SLD"
    end
    
    def attrs
      { 
        basket_mount: @order_detail.order.basket_mount,
        basket_id: current_basket_id,
        updated_by: Position::OPERATOR[:order_status]
      }
    end
    
    def pending_shares
      completed? ? position.pending_shares.to_i - @this_time_filled - remaining.to_i : position.pending_shares.to_i - @this_time_filled
    end
    
    def update_pending_shares
      $pms_logger.info("OrderStatus: 更新前挂起股数#{position.pending_shares}") if Setting.pms_logger
      position.update_attributes_with_lock(pending_shares: pending_shares)
      $pms_logger.info("OrderStatus: 更新后挂起股数#{position.pending_shares}") if Setting.pms_logger
    end
    
    def already_filled
      filled.to_i
    end
    
    def initial_pending_shares
      position.pending_shares.to_i + previous_total_filled
    end
    
    def create_order_log
      ::OrderLog.create!(order_log_attrs)
    end
    
    def order_log_attrs
      {
        user_id: @order_detail.user_id, 
        trading_account_id: @order_detail.trading_account_id, 
        base_stock_id: @stock.id, 
        ib_order_id: order_id, 
        order_id: @order_detail.order_id, 
        filled: @this_time_filled, 
        cost: @this_time_cost, 
        remaining: remaining.to_i, 
        total_filled: filled.to_i, 
        avg_price: avg_fill_price.to_d, 
        sequence: sequence,
        instance_id: instance_id
      }
    end
    
    def sequence
      ::OrderLog.where(ib_order_id: order_id).count + 1
    end
    
    def real_order_id
      basket_id.split(":")[1] if basket_id
    end
    
    def instance_id
      basket_id.split(":")[0] if basket_id
    end
    
  end
  
end
