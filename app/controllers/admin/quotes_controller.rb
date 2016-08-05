class Admin::QuotesController < Admin::ApplicationController
  before_action :load_base_stock, only: [:edit, :update]

  def edit
  end
  
  def update
    $redis.mapped_hmset("realtime:#{@base_stock.id}", secure_params)

    redirect_to list_admin_base_stocks_path
  end

  private

  def load_base_stock
    @base_stock = BaseStock.find(params[:id])
  end

  def secure_params
    params.slice("high52_weeks", "low52_weeks", "market_capitalization", "pe_ratio", "exchange", "symbol", "market", "trade_time", "previous_close",
      "open", "high", "low", "last", "volume", "total_value_trade", "change_from_previous_close", "percent_change_from_previous_close",
      "current_volume", "total_shares", "non_restricted_shares", "naps", "turnover", "five_days_volume", "eps", "num_trades", "trade_at")
  end
end
