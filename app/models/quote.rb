# 历史股票数据
#class Quote < ActiveRecord::Base
#  
#  # 初始日期
#  DEFAULT_DATE = '2009-01-01'
#
#  scope :date_since, -> (date) { date.present? ? where("date >= ?", date) : all }
#  scope :date_end, -> (date) { date.present? ? where("date <= ?", date) : all }
#  scope :asc_date, -> { order(date: :asc) }
#  scope :by_base_id, -> (base_stock_id) { where(base_id: base_stock_id) }
#  scope :by_date, -> (date) { where(date: date) }
#  scope :six_months, -> { where("date >= ?", 6.months.ago-3.day) }
#  
#  # 定义k线图方法
#  %w(kopen kclose khigh klow).each do |method_name|
#    define_method method_name do 
#      close.to_f.zero? ? 0.0 : send(method_name.slice(1..-1)) * adj_close / close
#    end
#  end
#
#  # 周标记
#  def week_flag
#    [date.year, date.cweek].join('_')
#  end
#
#  # 月标记
#  def month_flag
#    [date.year, date.month].join('_')
#  end
#   
#  def self.close_price_by_stock_and_date(stock, date, current_date_quote)
#    retry_times = 0
#    price = current_date_quote.try(:close)
#    $investment_logger.info "stock quote not exist - #{stock.id} - #{date}" if price.blank?
#    unless retry_times > 5 || price.present?
#      date = ClosedDay.get_work_day(date-1, stock.market_area)
#      price = where(:base_id => stock.id, :date => date).first.try(:close)
#      retry_times += 1
#    end
#    price || 0
#  end
#
#  def self.yesterday_price(stock_id)
#    cache_key = "stock_last_day_price_#{stock_id}_#{(Time.now-11.hours).strftime("%Y%m%d")}"
#    $cache.fetch(cache_key){ self.where(:base_id => stock_id).order("date desc").first.try(:close) || 0 }
#  end
#
#  def self.prices_in_52_weeks(stock_id)
#    quotes = Quote.where(:base_id => stock_id).date_since(52.weeks.ago.to_date)
#    quotes.sort_by{|q| q.date}.map{|q| q.adj_close.to_f}
#  end
#
#  def self.calculate_foreign_exchange(date)
#    self.calculate_cny_to_usd_exchange(date)
#    self.calculate_hkd_to_usd_exchange(date)
#    self.calculate_cny_to_hkd_exchange(date)
#    self.calculate_hkd_to_cny_exchange(date)
#  end
#
#  def self.kline_datas_by(stock_id)
#    datas = self.by_base_id(stock_id)
#    datas.map do |q|
#      {date: (q.date.to_time+8.hours).to_i*1000, open: q.kopen.to_f, high: q.khigh.to_f, low: q.klow.to_f, 
#       close: q.kclose.to_f, volume: q.volume, start_date: q.date.to_s, end_date: q.date.to_s}
#    end
#  end
#  
#  def self.stock_chart_datas(stock_id)
#    # 最近7个交易日的数据
#    
#    # stock_id = BaseStock.where(symbol: "700.HK").first.id #for_test
#    self.by_base_id(stock_id).order("date desc").limit(7).inject({}) {|sum, q| sum.merge(q.date.strftime("%m-%d") => q.adj_close.to_f)}
#  end
#
#  def self.grouped_indices_by(stock_ids, start_date, end_date)
#    Quote.where(base_id: stock_ids).date_since(start_date).date_end(end_date).group_by{|x| x.base_id}
#         .map{|base_id, quotes| [base_id, quotes.map{|q| [q.date.to_s(:db), q.index]}.to_h]}.to_h
#  end
#
#  def self.stock_indices_by(base_stock_id, start_date = nil, end_date = nil)
#    Quote.grouped_indices_by([base_stock_id], start_date, end_date)[base_stock_id] || {}
#  end
#
#  def self.stock_index_by(stock_id, date)
#    self.by_base_id(stock_id).by_date(date).first.try(:index)
#  end
#  
#  private
#  def self.calculate_cny_to_usd_exchange(date)
#    self.exchange_by_usd(BaseStock.cny_to_usd, BaseStock.usd_to_cny, date)
#  end
#
#  def self.calculate_hkd_to_usd_exchange(date)
#    self.exchange_by_usd(BaseStock.hkd_to_usd, BaseStock.usd_to_hkd, date)
#  end
#
#  def self.calculate_cny_to_hkd_exchange(date)
#    self.exchange_by_usd_agent(BaseStock.cny_to_hkd, BaseStock.usd_to_cny, BaseStock.usd_to_hkd, date)
#  end
#
#  def self.calculate_hkd_to_cny_exchange(date)
#    self.exchange_by_usd_agent(BaseStock.hkd_to_cny, BaseStock.usd_to_hkd, BaseStock.usd_to_cny, date)
#  end
#
#  # 通过美元转对应货币汇率反向计算
#  def self.exchange_by_usd(source_to_usd, usd_to_source, date)
#    usd_to_source_exchange = self.adj_close(usd_to_source.id, date)
#    return false if usd_to_source_exchange.blank?
#    attrs = {symbol: source_to_usd.symbol, base_id: source_to_usd.id, date: date}
#    Quote.create(attrs.merge(adj_close: 1/usd_to_source_exchange)) if Quote.where(attrs).blank?
#  end
#
#  # 通过美元做中间货币汇率计算
#  # params：要计算的汇率(source->target)，美元-来源汇率，美元-要转换的汇率
#  def self.exchange_by_usd_agent(source_to_target, usd_to_source, usd_to_target, date)
#    usd_to_source_exchange = self.adj_close(usd_to_source.id, date)
#    usd_to_target_exchange = self.adj_close(usd_to_target.id, date)
#    return false if usd_to_source_exchange.blank? || usd_to_target_exchange.blank?
#    attrs = {symbol: source_to_target.symbol, base_id: source_to_target.id, date: date}
#    Quote.create(attrs.merge(adj_close: usd_to_target_exchange/usd_to_source_exchange)) if Quote.where(attrs).blank?
#  end
#
#  def self.adj_close(base_stock_id, date)
#    Quote.where(:base_id => base_stock_id, :date => date).first.try(:adj_close)
#  end
#
# redis信息
#  include Redis::Objects
#  hash_key :redis_info, key: 'US_#{symbol_name}_daily_#{current_date}'
#
#end
