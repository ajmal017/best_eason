class Admin::BasketWeightLogsController < Admin::ApplicationController
  before_action :set_basket_weight_log, only: [:show, :edit, :update, :destroy]

  def index
    @q = BasketWeightLog.search(params[:q])
    @basket_weight_logs = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @basket_weight_log = BasketWeightLog.new
  end

  def edit
  end

  def create
    @basket_weight_log = BasketWeightLog.new(basket_weight_log_params)

    if @basket_weight_log.save
      redirect_to [:admin, @basket_weight_log], notice: 'Basket weight log was successfully created.'
    else
      render :new
    end
  end

  def update
    if @basket_weight_log.update(basket_weight_log_params)
      redirect_to [:admin, @basket_weight_log], notice: 'Basket weight log was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @basket_weight_log.destroy
    redirect_to admin_basket_weight_logs_url, notice: 'Basket weight log was successfully destroyed.'
  end

  private
  
  def set_basket_weight_log
    @basket_weight_log = BasketWeightLog.find(params[:id])
  end

  def basket_weight_log_params
    params.require(:basket_weight_log).permit(:stock_id, :basket_id, :adjusted_weight, :date)
  end
end
