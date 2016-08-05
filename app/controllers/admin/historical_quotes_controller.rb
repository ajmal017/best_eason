class Admin::HistoricalQuotesController < Admin::ApplicationController
  before_action :set_historical_quote, only: [:show, :edit, :update, :destroy]

  def index
    @q = HistoricalQuote.search(params[:q])
    @historical_quotes = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @historical_quote = HistoricalQuote.new
  end

  def edit
  end

  def create
    @historical_quote = HistoricalQuote.new(historical_quote_params)

    if @historical_quote.save
      redirect_to [:admin, @historical_quote], notice: 'Historical quote was successfully created.'
    else
      render :new
    end
  end

  def update
    if @historical_quote.update(historical_quote_params)
      redirect_to [:admin, @historical_quote], notice: 'Historical quote was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @historical_quote.destroy
    redirect_to admin_historical_quotes_url, notice: 'Historical quote was successfully destroyed.'
  end

  private
  
  def set_historical_quote
    @historical_quote = HistoricalQuote.find(params[:id])
  end

  def historical_quote_params
    params.require(:historical_quote).permit(:base_stock_id, :symbol, :last, :open, :high, :low, :last_close, :change_from_open, :percent_change_from_open, :change_from_last_close, :percent_change_from_last_close, :index, :volume, :date, :currency, :ma5, :ma10, :ma20, :ma30)
  end
end
