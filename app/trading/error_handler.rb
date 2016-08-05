module Trading
  
  class ErrorHandler
    
    include InitHelper
    
    ERROR_CODE = {
      order_cancelling: '202',
      exchange_closed: '201',
      no_order: '135',
      closed: '399',
      cancell_attempt: '161',
      order_held: '404'
    }
    
    def perform
      if basket_exists? && order_detail
        $pms_logger.info("Error Happen: error_coe=#{error_code},error_string=#{error_string}") if Setting.pms_logger
        case error_code
        when ERROR_CODE[:order_cancelling]
          # order_detail.notify_error("取消中：请稍候")
          $pms_logger.info("Error Happen: 通知用户正在取消") if Setting.pms_logger
        when ERROR_CODE[:no_order]
          $pms_logger.info("Error Happen: 通知用户无法取消") if Setting.pms_logger
          #order_detail.notify_error("取消失败：订单已执行，无法取消！")
        when ERROR_CODE[:exchange_closed]
          $pms_logger.info("error_code#{error_code}, error_string=#{error_string}") if Setting.pms_logger
        when ERROR_CODE[:closed]
          $pms_logger.info("处于闭市状态， error_code#{error_code}") if Setting.pms_logger
        when ERROR_CODE[:cancell_attempt]
          $pms_logger.info("订单处在不能取消的状态， error_code#{error_code}") if Setting.pms_logger
        when ERROR_CODE[:order_held]
          $pms_logger.info("做空订单， error_code#{error_code}") if Setting.pms_logger
        else
          $pms_logger.info("Error Happen: 订单出错，此订单不会继续进行") if Setting.pms_logger
          with_transaction
        end
        
        order_detail.order.order_errs.create(ib_order_id: order_id, symbol: symbol, code: error_code, message: error_string) rescue nil
      end
    end
    
    def with_transaction
      ActiveRecord::Base.transaction do
        order_detail.adjust! if order_detail.may_adjust?
      end
    end
    
    def order_cancel?
      error_code == '202'
    end
    
    def order_detail
      @order_detail ||= ::OrderDetail.find_by(instance_id: instance_id, order_id: real_order_id, base_stock_id: stock.id)
    end
    
    def stock
      @stock ||= ::BaseStock.find_by(ib_symbol: symbol)
    end
    
    def real_order_id
      basket_id.split(":")[1] if basket_id
    end
    
    def instance_id
      basket_id.split(":")[0] if basket_id
    end
    
    def basket_exists?
      basket_id rescue nil
    end
    
  end
  
end
