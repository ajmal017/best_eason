module Trading
  
  class Commission
    include InitHelper
    
    def compute
      if api_order
        order_detail.update_commission(commission) 
        order_detail.order.update_commission(commission)
        api_order.process!
      end
    end
    
    def processed?
      api_order.try(:processed?)
    end
    
    def create_commission
      ::CommissionReport.find_or_initialize_by(key).update(attrs)
    end
    
    private
    def order_detail
      @order_detail || ( @order_detail = ::OrderDetail.fetch_one_by(api_order.contract_id, api_order.symbol, api_order.order_id) )
    end
    
    def api_order
      @api_order || ( @api_order = ::ApiExec.find_by(exec_id: exec_id) )
    end
    
    def attrs
      {
        realized_pnl: realized_pnl,
        yield_redemption_date: yield_redemption_date,
        currency: currency,
        commission: commission,
        yield: self.send(:yield)
      }
    end
    
    def key
      { exec_id: exec_id }
    end
  end
  
end