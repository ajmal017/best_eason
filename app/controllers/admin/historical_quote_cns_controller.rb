class Admin::HistoricalQuoteCnsController < Admin::ApplicationController
  before_action :set_historical_quote_cn, only: [:show, :edit, :update, :destroy]

  def index
    @q = HistoricalQuoteCn.search(params[:q])
    @historical_quote_cns = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @historical_quote_cn = HistoricalQuoteCn.new
  end

  def edit
  end

  def create
    @historical_quote_cn = HistoricalQuoteCn.new(historical_quote_cn_params)

    if @historical_quote_cn.save
      redirect_to [:admin, @historical_quote_cn], notice: 'Historical quote cn was successfully created.'
    else
      render :new
    end
  end

  def update
    if @historical_quote_cn.update(historical_quote_cn_params)
      redirect_to [:admin, @historical_quote_cn], notice: 'Historical quote cn was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @historical_quote_cn.destroy
    redirect_to admin_historical_quote_cns_url, notice: 'Historical quote cn was successfully destroyed.'
  end

  private
  
  def set_historical_quote_cn
    @historical_quote_cn = HistoricalQuoteCn.find(params[:id])
  end

  def historical_quote_cn_params
    params.require(:historical_quote_cn).permit(:base_stock_id, :symbol, :last, :open, :high, :low, :last_close, :change_from_open, :percent_change_from_open, :change_from_last_close, :percent_change_from_last_close, :index, :volume, :date, :currency, :ma5, :ma10, :ma20, :ma30)
  end
end
