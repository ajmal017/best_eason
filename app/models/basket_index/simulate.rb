# 预估的主题指数：用户创建主题时往前预估主题表现
class BasketIndex::Simulate
  PEROID_DAYS = {"1周" => 8, "1月" => 30, "3月" => 91, "6月" => 182, "1年" => 366, "5年" => 1825}
  attr_accessor :tickers_hash, :market_area

  # tickers = {symbol: weight, ...}
  def initialize(tickers)
    tickers ||= {}
    @tickers_hash = tickers.each{|k,v| tickers[k] = BigDecimal.new(v.to_s)}
    @market_area = BaseStock.market_area_by_symbols(tickers.keys)
  end

  def self.indices(tickers_hash, start_date, end_date)
    BasketIndex::Simulate.new(tickers_hash).indices(start_date, end_date)
  end

  def self.indices_for_chart(tickers_hash, time_period)
    indices = BasketIndex::Simulate.new(tickers_hash).indices_by_period(time_period)
    indices.map do |date_str, index|
      [Time.parse("#{date_str} 00:00:00 UTC").to_i * 1000, (index - indices[0][1])/10]
    end
  end

  def indices_by_period(time_period)
    indices_by_days(PEROID_DAYS[time_period])
  end
  
  def indices_by_days(days)
    end_date = Date.today
    start_date = end_date - days
    indices(start_date, end_date)
  end
  
  def indices(start_date, end_date)
    return [] if tickers_invalid?

    start_date = ClosedDay.get_work_day_after(start_date, market_area)
    indices, first_day_indices = {}, {}
    stocks_indices = stock_history_indices(start_date, end_date)

    (start_date..end_date).each do |date|
      next if !ClosedDay.is_workday?(date, market_area)
      index = calculate(date, stocks_indices, indices, first_day_indices)
      indices[date.to_s(:db)] = index if index.present?
    end
    indices.to_a.sort_by{|date, idx| date}
  end

  private
  def calculate(date, stocks_indices, indices, first_day_indices)
    stocks_returns = cal_stock_returns(date, stocks_indices, first_day_indices)
    return 1000 if first_day_indices.present? && indices.blank?
    return nil if indices.blank? || can_not_calculate_this_day_index?(stocks_returns, first_day_indices)
    return pre_index(stocks_returns)
  end

  def cal_stock_returns(date, stocks_indices, first_day_indices)
    stocks_return = {}
    tickers_hash.each do |symbol, weight|
      next if cash_symbol?(symbol)
      stock_index = stocks_indices[symbol][date.to_s(:db)]
      if first_day_indices[symbol].nil?
        first_day_indices[symbol] = stock_index.to_f if stock_index.present?
        stocks_return[symbol] = nil
        next
      end
      stocks_return[symbol] = stock_index.nil? ? nil : stock_index.to_f/first_day_indices[symbol].to_f - 1
    end
    stocks_return
  end

  def pre_index(stocks_return)
    sum = stocks_return.map{|symbol, s_return| s_return.to_f * tickers_hash[symbol]}.inject{|sum, num| sum+=num}.to_f
    (1000 * (1 + sum)).round(2)
  end

  # 如果全部股票没有stock_index数据，并且计算时间段内全部股票都有first day index，则不计算当天的basket pre index值
  # 目的：创建主题时图表，如果最近一些天没有及时的拿到index数据，则不计算；该股票上市前的时期则按0计算
  def can_not_calculate_this_day_index?(stocks_return, first_day_indices)
    all_nil_values?(stocks_return) && first_day_index_all_nil?(first_day_indices)
  end
  
  def all_nil_values?(stocks_return)
    # 过滤掉cash的
    stocks_return.reject{|sym, _| sym == Stock::Cash.symbol}.values.uniq.compact.blank?
  end

  def first_day_index_all_nil?(first_day_indices)
    first_day_indices.reject{|sym, _| sym == Stock::Cash.symbol}.values.all?
  end

  def tickers_invalid?
    tickers_hash.blank? || weights_not_eql_one?
  end

  def weights_not_eql_one?
    tickers_hash.values.inject{|sum, value| sum+=value} != 1
  end

  def stock_history_indices(start_date, end_date)
    symbols = tickers_hash.keys
    stocks_indices = {}
    symbol_and_base_stock_ids = BaseStock.where(symbol: symbols).map{|bs| [bs.symbol, bs.id]}.to_h
    historical_quote_class = market_area.to_s == "cn" ? HistoricalQuoteCn : HistoricalQuote
    grouped_stock_indices = historical_quote_class.grouped_indices_by(symbol_and_base_stock_ids.values, start_date, end_date)
    symbol_and_base_stock_ids.each do |symbol, base_stock_id|
      stocks_indices[symbol] = grouped_stock_indices[base_stock_id] || {}
    end
    # cash indices, all 1000, with symbol: cash.cash
    stocks_indices.merge(Stock::Cash.symbol => Stock::Cash.indices_by(start_date, end_date))
  end

  def cash_symbol?(symbol)
    Stock::Cash.symbol == symbol
  end
end