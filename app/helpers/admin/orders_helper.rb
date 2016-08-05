module Admin::OrdersHelper
  def order_status_for_search
    Order::STATUS.delete_if{|k,v| k == 'unconfirmed'}.map{|k,v| [v, k]}
  end
end