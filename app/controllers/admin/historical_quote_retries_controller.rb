class Admin::HistoricalQuoteRetriesController < Admin::ApplicationController
  before_action :set_historical_quote_retry, only: [:show, :edit, :update, :destroy]

  def index
    @q = HistoricalQuoteRetry.search(params[:q])
    @historical_quote_retries = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @historical_quote_retry = HistoricalQuoteRetry.new
  end

  def edit
  end

  def create
    @historical_quote_retry = HistoricalQuoteRetry.new(historical_quote_retry_params)

    if @historical_quote_retry.save
      redirect_to [:admin, @historical_quote_retry], notice: 'Historical quote retry was successfully created.'
    else
      render :new
    end
  end

  def update
    if @historical_quote_retry.update(historical_quote_retry_params)
      redirect_to [:admin, @historical_quote_retry], notice: 'Historical quote retry was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @historical_quote_retry.destroy
    redirect_to admin_historical_quote_retries_url, notice: 'Historical quote retry was successfully destroyed.'
  end

  private
  
  def set_historical_quote_retry
    @historical_quote_retry = HistoricalQuoteRetry.find(params[:id])
  end

  def historical_quote_retry_params
    params.require(:historical_quote_retry).permit(:base_stock_id, :date, :trading_date, :number)
  end
end
