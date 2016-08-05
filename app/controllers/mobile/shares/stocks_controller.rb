class Mobile::Shares::StocksController < Mobile::ApplicationController
  layout false
  skip_before_filter :verify_authenticity_token unless Rails.env.production?
  before_filter :get_stock, except: [:index]
  def show
    redirect_to mobile_link("/stocks/#{params[:id]}")
    @page_title = @stock.c_name
  end

  

  def chart_datas
  end

  def graph
  end

  def graph_datas
    one_day_minutes = ChartLine.one_day_minutes(@stock)
    start_trade_time = @stock.prev_latest_start_time
    end_trade_time = @stock.prev_latest_end_time
    render json: {
      one_day_minutes: one_day_minutes, change_from_previous_close: @stock.change_from_previous_close, previous_close: @stock.previous_close
    }
  end
private
  def get_stock
    @stock = BaseStock.find(params[:id])
  end

  
end
