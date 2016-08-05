class Admin::AdjustedStocksController < Admin::ApplicationController

  def index
    params[:type] ||= "add"
    params[:contest] ||= "2"
  	if params[:start_time] && params[:end_time]
      @start_time, @end_time = Time.parse(params[:start_time]), Time.parse(params[:end_time])
  	else
      exchange = Exchange::Base.by_area(:cn)
      @start_time, @end_time = exchange.trade_time_range
    end
    b_ids = basket_ids(params[:top], params[:contest])
    @logs = BasketAdjustLog.contest_adjusted_stocks(params[:type], @start_time, @end_time, params[:contest], b_ids)
  end

  private

  def basket_ids(top, contest)
    if top.present?
      if contest.to_s == "2"
        BasketRankCache.top(params[:top].to_i).keys
      else
        BasketRank.top(contest, params[:top].to_i).keys
      end
    else
      nil
    end
  end
end