class Admin::OrderDetailsController < Admin::ApplicationController
  before_action :set_order_detail, only: [:show, :edit, :update, :destroy]

  def index
    @q = OrderDetail.search(params[:q])
    @order_details = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @order_detail = OrderDetail.new
  end

  def edit
  end

  def create
    @order_detail = OrderDetail.new(order_detail_params)

    if @order_detail.save
      redirect_to [:admin, @order_detail], notice: 'Order detail was successfully created.'
    else
      render :new
    end
  end

  def update
    if @order_detail.update(order_detail_params)
      redirect_to [:admin, @order_detail], notice: 'Order detail was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @order_detail.destroy
    redirect_to admin_order_details_url, notice: 'Order detail was successfully destroyed.'
  end

  private
  
  def set_order_detail
    @order_detail = OrderDetail.find(params[:id])
  end

  def order_detail_params
    params.require(:order_detail).permit(:order_id, :instance_id, :base_stock_id, :user_id, :basket_id, :est_shares, :real_shares, :est_cost, :real_cost, :status, :symbol, :ib_order_id, :trade_type, :trade_time, :order_type, :limit_price, :updated_by, :commission, :background, :average_cost, :market, :currency, :cash_id, :trading_account_id, :rt_order_id, :result)
  end
end
