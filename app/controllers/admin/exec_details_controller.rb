class Admin::ExecDetailsController < Admin::ApplicationController
  before_action :set_exec_detail, only: [:show, :edit, :update, :destroy]

  def index
    @q = ExecDetail.search(params[:q])
    @exec_details = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @exec_detail = ExecDetail.new
  end

  def edit
  end

  def create
    @exec_detail = ExecDetail.new(exec_detail_params)

    if @exec_detail.save
      redirect_to [:admin, @exec_detail], notice: 'Exec detail was successfully created.'
    else
      render :new
    end
  end

  def update
    if @exec_detail.update(exec_detail_params)
      redirect_to [:admin, @exec_detail], notice: 'Exec detail was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @exec_detail.destroy
    redirect_to admin_exec_details_url, notice: 'Exec detail was successfully destroyed.'
  end

  private
  
  def set_exec_detail
    @exec_detail = ExecDetail.find(params[:id])
  end

  def exec_detail_params
    params.require(:exec_detail).permit(:basket_id, :order_id, :instance_id, :exchange, :currency, :symbol, :contract_id, :account_name, :avg_price, :cum_quantity, :exec_exchange, :exec_id, :ib_order_id, :perm_id, :price, :shares, :side, :time, :ev_rule, :ex_multiplier, :processed, :type, :user_id, :stock_id, :trading_account_id, :rt_order_id)
  end
end
