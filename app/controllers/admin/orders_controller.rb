class Admin::OrdersController < Admin::ApplicationController
  
  def index
    @page_title = "订单管理"
    search_query = params[:q]
    if search_query and search_query[:instance_id_eq] == 'basket'
      search_query[:instance_id_not_eq] = 'others'
      search_query.delete(:instance_id_eq)
    end
    @q = Order.normal.includes(:user, :stock_detail).search_by_created_at(params[:created_at_gteq], params[:created_at_lteq]).search(search_query)
    @orders = @q.result.order("id desc").paginate(page: params[:page] || 1, per_page: 10).to_a
  end

  def show
    @order = Order.find(params[:id])
  end

  def update
    @order = Order.find(params[:id])
    begin
      @order.admin_cancell!
      notice = "取消成功."
    rescue AASM::InvalidTransition => e
      notice = "取消失败.#{e.message}"
    end
    redirect_to admin_orders_path, notice: notice
  end

  def log
    @order_logs = OrderLog.where(order_id: params[:id], base_stock_id: params[:base_stock_id]).order("sequence asc").includes(:base_stock)
    @exec_details = ApiExec.where(order_id: params[:id], stock_id: params[:base_stock_id]).order("exec_id asc").includes(:stock)
  end

  def execution
    Order.find(params[:id]).user.user_binding.request_execution
    redirect_to admin_order_path, notice: '已经将request_execution发往cts'
  end
end
