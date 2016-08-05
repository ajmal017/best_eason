class Admin::GuessIndicesController < Admin::ApplicationController

  def index
    @dates = GuessIndex.select("distinct date").map(&:date).map{|d| d.to_s(:db)}.sort
    @date = params[:date] || @dates.last
    @grouped_datas = GuessIndex.chart_datas(@date)
    @market_closed = @date < Date.today.to_s(:db) || (@date == Date.today.to_s(:db) && !GuessIndex.exchange.trading?)
    @final_index = GuessIndex.final_index(@date)
  end

end