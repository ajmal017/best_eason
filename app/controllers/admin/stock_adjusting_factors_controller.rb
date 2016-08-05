class Admin::StockAdjustingFactorsController < Admin::ApplicationController
  before_action :set_stock_adjusting_factor, only: [:show, :edit, :update, :destroy]

  def index
    @q = StockAdjustingFactor.search(params[:q])
    @stock_adjusting_factors = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @stock_adjusting_factor = StockAdjustingFactor.new
  end

  def edit
  end

  def create
    @stock_adjusting_factor = StockAdjustingFactor.new(stock_adjusting_factor_params)

    if @stock_adjusting_factor.save
      redirect_to [:admin, @stock_adjusting_factor], notice: 'Stock adjusting factor was successfully created.'
    else
      render :new
    end
  end

  def update
    if @stock_adjusting_factor.update(stock_adjusting_factor_params)
      redirect_to [:admin, @stock_adjusting_factor], notice: 'Stock adjusting factor was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @stock_adjusting_factor.destroy
    redirect_to admin_stock_adjusting_factors_url, notice: 'Stock adjusting factor was successfully destroyed.'
  end

  private
  
  def set_stock_adjusting_factor
    @stock_adjusting_factor = StockAdjustingFactor.find(params[:id])
  end

  def stock_adjusting_factor_params
    params.require(:stock_adjusting_factor).permit(:base_stock_id, :inner_code, :ex_divi_date, :adjusting_factor, :adjusting_const, :ratio_adjusting_factor, :xgrq, :accu_cash_divi, :accu_bonus_share_ratio)
  end
end
