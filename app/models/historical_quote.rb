# XIGNITE历史数据
class HistoricalQuote < ActiveRecord::Base
  
  scope :date_since, -> (date) { date.present? ? where("date >= ?", date) : all }
  scope :date_end, -> (date) { date.present? ? where("date <= ?", date) : all }
  scope :asc_date, -> { order(date: :asc) }
  scope :by_base_stock_id, -> (base_stock_id) { where(base_stock_id: base_stock_id) }
  scope :by_date, -> (date) { where(date: date) }
  scope :six_months, -> { where("date >= ?", 6.months.ago-3.day) }
  
  # 定义k线图方法
  %w(kopen khigh klow).each do |m|
    define_method(m, Proc.new{ send(m.slice(1..-1)) })
  end

  alias_attribute :kclose, :last

  # 周标记
  def week_flag
    [date.cwyear, date.cweek].join('_')
  end

  # 月标记
  def month_flag
    [date.year, date.month].join('_')
  end

  def self.prices_in_52_weeks(stock_id)
    quotes = self.where(:base_stock_id => stock_id).select(:last).date_since(52.weeks.ago.to_date).order(:date)
    quotes.map{|q| q.last.to_f}
  end

  def self.kline_datas_by(stock_id)
    datas = self.by_base_stock_id(stock_id)
    datas.map do |q|
      {date: (q.date.to_time+8.hours).to_i*1000, open: q.kopen.to_f, high: q.khigh.to_f, low: q.klow.to_f, 
       close: q.kclose.to_f, volume: q.volume, start_date: q.date.to_s, end_date: q.date.to_s}
    end
  end
  
  def self.stock_chart_datas(base_stock)
    # 最近7个交易日的数据
    start_date = ClosedDay.prev_workday_of(7, base_stock.market_area)
    RestClient.api.stock.prices(base_stock.id, start_date: start_date, end_date: Date.today, precision: 'days')
  end

  def self.grouped_indices_by(stock_ids, start_date, end_date)
    self.where(base_stock_id: stock_ids).where("date >= ? and date <= ?", start_date, end_date)
         .select(:base_stock_id, :date, :index).group_by{|x| x.base_stock_id}
         .map{|base_stock_id, quotes| [base_stock_id, quotes.map{|q| [q.date.to_s(:db), q.index]}.to_h]}.to_h
  end

  # dates 不一定连续
  def self.grouped_indices_by_dates(stock_ids, dates)
    self.where(base_stock_id: stock_ids, date: dates)
         .select(:base_stock_id, :date, :index).group_by{|x| x.base_stock_id}
         .map{|base_stock_id, quotes| [base_stock_id, quotes.map{|q| [q.date.to_s(:db), q.index]}.to_h]}.to_h
  end

  def self.stock_indices_by(base_stock_id, start_date = nil, end_date = nil)
    self.grouped_indices_by([base_stock_id], start_date, end_date)[base_stock_id] || {}
  end

  def self.stock_indices_by_dates(base_stock_id, datas)
    indices = self.where(base_stock_id: base_stock_id, date: datas).select(:base_stock_id, :date, :index).map{|q| [q.date.to_s(:db), q.index]}.to_h
    indices || {}
  end

  def self.stock_index_by(stock_id, date)
    self.by_base_stock_id(stock_id).by_date(date).select(:index).first.try(:index)
  end

  def self.stocks_close_prices(stock_ids, date)
    where(base_stock_id: stock_ids, date: date).select(:base_stock_id, :last_close)
      .pluck(:base_stock_id, :last_close).to_h
  end

  def self.price_by(stock_id, date)
    find_by(base_stock_id: stock_id, date: date).last rescue 0
  end
end
