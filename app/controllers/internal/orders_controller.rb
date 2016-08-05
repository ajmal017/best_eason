class Internal::OrdersController < Internal::BaseController

  def completed
    Resque.enqueue(AdjustBasketByOrderWorker, params[:id])
    $adjust_basket_by_order_loger.info("#{Time.now} resque enqueue order_id: #{params[:id]}")
    render json: {status: true}
  end
end