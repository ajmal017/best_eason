class HistoricalQuoteCn < ActiveRecord::Base
  # 定义k线图方法
  alias_attribute :close, :last
  alias_attribute :start_date, :date
  alias_attribute :end_date, :date

  scope :by_base_stock_id, -> (base_stock_id) { where(base_stock_id: base_stock_id) }
  scope :gte_date, -> (date) { where("date >= ?", date) if date.present? }
  scope :lte_date, -> (date) { where("date <= ?", date) if date.present? }
  scope :asc_date, -> { order(date: :asc) }
  scope :by_date, -> (date) { where(date: date) }

  # 周标记
  def week_flag
    [date.cwyear, date.cweek].join('_')
  end

  # 月标记
  def month_flag
    [date.year, date.month].join('_')
  end

  def as_json(options = {})
    options.reverse_merge!(only: json_attrs, methods: json_methods)

    super(options).merge('date' => datestamps)
  end

  def self.kline_datas_by(base_stock_id)
    by_base_stock_id(base_stock_id).map { |quote| quote.as_json }
  end

  def self.grouped_indices_by(stock_ids, start_date, end_date)
    self.where(base_stock_id: stock_ids).where("date >= ? and date <= ?", start_date, end_date)
        .select(:base_stock_id, :date, :index).group_by{|x| x.base_stock_id}
        .map{|base_stock_id, quotes| [base_stock_id, quotes.map{|q| [q.date.to_s(:db), q.index]}.to_h]}.to_h
  end

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

  # 重置停牌股票的交易时间
  def self.reset_trade_time(stock_id)
    quote = self.where(base_stock_id: stock_id).where("volume > 0").order(date: :desc).first
    if quote
      $redis.mapped_hmset("realtime:#{stock_id}",{trade_time: "#{quote.date.to_s(:db)} 15:00:00"})
    end
  end

  def self.price_by(stock_id, date)
    find_by(base_stock_id: stock_id, date: date).last rescue 0
  end

  private

  def json_attrs
    %w(open high low volume)
  end

  def json_methods
    %w(close start_date end_date)
  end

  def datestamps
    (date.to_time + 8.hours).to_i * 1000
  end
end
