class Ajax::OrdersController < Ajax::ApplicationController
  before_filter :authenticate_user!
  before_action :find_order, except: [:orders_infos, :data]

  # 订单数据
  # => json
  def data
    # @in_progress_orders = current_user.orders.in_progress.order("created_at desc").includes(:order_details => :stock)

    # order_details = @order.order_details.map{|od| {stock_id: od.base_stock_id, real_shares: od.real_shares.to_i, status: od.status_name, avg_price: od.avg_price}}
    # render json: @in_progress_orders.as_json(
    #     only: [:id, :real_cost], 
    #     methods: [:percent_complete], 
    #     include: {
    #       order_details: {
    #         only: [:id, :order_id, :real_shares, :est_shares, :real_cost, :trade_time], 
    #         methods: [:avg_price, :status_name]
    #       }
    #     }
    #   )

    render json: Order.first.to_event_json.target!
  end


  # 历史订单查看详情
  def details
    
  end

  def status
    status = @order.confirmed?
    render :json => {completed: status}
  end
  
  def cancel
    if @order.can_cancel?
      @order.cancel_by_user
      status = true
    else
      status = false 
    end
    render :json => {status: status}
  end

  def orders_infos
    ids = params[:order_ids].to_s.split(",")
    orders = current_user.orders.where(id: ids).includes(:basket).includes(:order_details => :stock)
    infos = orders.map do |order|
      {
        id: order.id, real_shares: order.real_shares, status_name: order.status_name, 
        currency_unit: order.currency_unit, real_cost: order.real_cost, 
        avg_cost: order.basket? ? "--" : order.order_details.first.avg_price,
        can_cancel: order.can_cancel?
      }
    end
    render json: infos
  end

  private
  def find_order
    @order = current_user.orders.find(params[:id])
  end
end
