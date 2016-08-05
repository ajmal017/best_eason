class BasketIndex::Realtime < BasketIndex::Real
  attr_accessor :basket, :date, :market_area, :basket_index, :stock_weights, :realtime_index, :last_day

  def initialize(basket)
    @basket = basket
    @date = Exchange::Base.by_area(basket.get_area).prev_latest_market_date
    @market_area = basket.market
    @basket_index = BasketIndex.where(basket_id: basket.id, date: date).first
    @last_day = ClosedDay.get_work_day(@date - 1, @market_area)
    @stock_weights = get_stock_weights
    @realtime_index = nil
  end

  def self.cached_index(basket)
    cache_key = "basket_realtime_index_#{basket.id}"
    $cache.fetch(cache_key, :expires_in => 2.minutes){ self.new(basket).get_index }
  end

  def get_index
    realtime_index.present? ? realtime_index : calculate
  end

  def calculate
    # todo
    # @realtime_index = basket_index.present? ? basket_index.index : super
    super
  end

  def self.change_percent_cached(basket)
    cache_key = "basket_realtime_change_percent_#{basket.id}"
    $cache.fetch(cache_key, :expires_in => 2.minutes){ self.new(basket).change_percent }
  end

  def change_percent
    # todo
    # if basket_index.present?
    #   basket.one_day_return.to_f.round(2)
    # else
    #   latest_index = basket.latest_basket_index.try(:index) || 1000
    #   realtime_index = get_index || 1000
    #   Caishuo::Utils::Helper.div_percent(realtime_index - latest_index, latest_index).round(2)
    # end
    latest_index = BasketIndex.get_index_by(basket.id, last_day) || 1000
    # latest_index = basket.latest_basket_index.try(:index) || 1000
    realtime_index = get_index || 1000
    Caishuo::Utils::Helper.div_percent(realtime_index - latest_index, latest_index).round(2)
  end
  
  private
  def get_stock_weights
    # BasketWeightLog.stock_adjusted_weights(basket.id, last_day)
    basket.stock_adjusted_weights
  end

  def trading_stocks_close_prices(stock_ids)
    BasketIndex::StockReturn.stocks_realtime_prices(stock_ids)
  end

  def holding_stock_rets(stock_ids)
    BasketIndex::StockReturn.realtime_rets(stock_ids)
  end

  def log_current_weights
    # do nothing
  end

  def set_adjusted_weights
    # do nothing
  end
end