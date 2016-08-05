require 'detail_attrs'
module Trading
  
  class ApiDetail
    extend Forwardable
    
    def_delegators :order_detail, :previous_total_filled, :previous_total_cost, :est_shares
    def_delegators :position, :initial_pending_shares, :initial_shares, :position_previous_cost
    
    include InitHelper
    def initialize(options, account)
      super(options)
      @exec_order = ::ExecDetail.find_by(key_attrs)
      @account = account
      @stock = ::BaseStock.find_by(ib_id: contract_id) || ::BaseStock.find_by!(ib_symbol: symbol)
    end

    def position
      @position ||= ::Position.find_or_create_by(instance_id: instance_id, base_stock_id: @stock.id, trading_account_id: @account.id).copy_attrs(position_attrs)
    end

    def order_detail
      @order_detail ||= ::OrderDetail.fetch_one_by(contract_id, symbol, real_order_id)
    end
    
    def create_api_order
      ::ApiExec.find_or_initialize_by(key_attrs).update(api_attrs)
    end
    
    def valid?
      self.cum_quantity.to_i <= self.est_shares.try(:to_i)
    end
    
    def reconcile
      $pms_logger.info("ExecDetails Api: #{type},#{basket_id},#{symbol},#{avg_price},#{shares},#{side},#{exec_id}")  if Setting.pms_logger
      ActiveRecord::Base.transaction do
        if order_detail && order_detail.may_reconcile?
          position.reconcile(reconciled_attrs)
          order_detail.reconcile(nil, cum_quantity.to_d, avg_price, time)
        end
      end
    end

    private
    include DetailAttrs
    def api_attrs
      shared_attrs.merge(basket_id: basket_id, instance_id: instance_id, order_id: real_order_id)
    end
    
    def instance_id
      basket_id.split(":")[0] if basket_id
    end
    
    def real_order_id
      basket_id.split(":")[1] if basket_id
    end
    
    def reconciled_attrs
      sell? ? sell_reconciled_attrs : buy_reconciled_attrs
    end
    
    def buy_reconciled_attrs
      { shares: initial_shares + this_time_filled, average_cost: position_avg_cost }
    end
    
    def sell_reconciled_attrs
      { shares: initial_shares - this_time_filled, pending_shares: pending_shares }
    end
    
    def reconciled_shares
      sell? ? initial_shares - this_time_filled : initial_shares + this_time_filled
    end
    
    def pending_shares
      initial_pending_shares - this_time_filled
    end
    
    def sell?
      side == "SLD"
    end
    
    def position_avg_cost
      reconciled_shares.to_i == 0 ? 0 : total_cost/reconciled_shares
    end
    
    def total_cost
      position_previous_cost + this_time_cost
    end
    
    def this_time_cost
      cum_quantity.to_f * avg_price.to_f - previous_total_cost
    end
    
    def this_time_filled
      cum_quantity.to_i - previous_total_filled
    end
    
    def position_attrs
      { 
        basket_id: order_detail.basket_id, 
        basket_mount: order_detail.order.basket_mount, 
        updated_by: ::Position::OPERATOR[:reconcile] 
      }
    end
  end
  
end
