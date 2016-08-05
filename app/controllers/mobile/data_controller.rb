class Mobile::DataController < Mobile::ApplicationController
  layout false
  
  def basket_chart_datas
    @basket = Basket.find(params[:id])
    begin_date = @basket.adjust_start_date
    market_data = @basket.market_indices_with_realtime_point(begin_date)
    basket_data = @basket.real_indices_with_realtime_point(begin_date)

    render :json => {market: market_data, basket: basket_data}
  end


  def stock_quote_prices
    @stock = BaseStock.find(params[:id])
    one_day_minutes, week_minutes = ChartLine.cached_minute_prices(@stock)
    render json: {one_day_minutes: one_day_minutes, week_minutes: week_minutes, previous_close: @stock.previous_close}, callback: params[:callback]
  end

  def stock_klines
    @stock = BaseStock.find(params[:id])
    start_date = params[:limit] ? params[:limit].to_i.days.ago : nil
    @kline_datas = RestClient.api.stock.kline(params[:id], params[:type], start_date)
    add_realtime_kline_datas unless params[:end_date]
    render json: @kline_datas, callback: params[:callback]
  end


  private

  def add_realtime_kline_datas
    if @stock.market_open?
      realtime_data = @stock.realtime_kline_data(params[:type])
      if @kline_datas.last["start_date"] < realtime_data[:start_date]
        @kline_datas.push(realtime_data)
      else
        last_point = @kline_datas.last
        last_point["high"] = [last_point["high"], realtime_data[:high]].max
        last_point["low"] = [last_point["low"], realtime_data[:low]].min
        last_point.merge!("close" => realtime_data[:close], "end_date" => realtime_data[:end_date], "date" => realtime_data[:date])
      end
    end
  end

end