class RtQuote < ActiveRecord::Base

  attr_accessor :last_trade_time, :last_trade_date

  scope :by_base_stock_id, -> (base_stock_id) { where(base_stock_id: base_stock_id) }

  scope :trade_with, -> (*times) { where("trade_time >= ? and trade_time <= ?", times.first, times.last).order(trade_time: :desc) }
  
  scope :trade_on, -> (date) { where(local_date: date) }

  scope :desc_trade_time, -> { order(trade_time: :desc) }

  EXPIRED_DAYS = 10.days

  def self.import_to_mysql(keys, data, options={})
    return if keys.blank?
    import(keys, data, options.merge(ignore: true))
  end

  def self.intraday_data(base_stock_id, since_date)
    RtQuote.by_base_stock_id(base_stock_id).select(:market, :trade_time, :volume, :last, :local_date)
    .where(["trade_time >= ?", since_date]).order(:trade_time)
  end

  # 交易所当地时间
  def local_trade_time
    return unless trade_time
    trade_time + utc_offset
  end

  def utc_offset
    trade_time.in_time_zone(time_zone).utc_offset
  end

  def time_zone
    market == 'us' ? "Eastern Time (US & Canada)" : "Beijing"
  end


  # 以下是Redis历史数据迁移，将会被删除
  # IntradayQuote.restore_from_redis
  def self.restore_from_redis
    expired_at = EXPIRED_DAYS.since.to_date
    BaseStock.find_each(batch_size: 200) do |stock|
      puts "Start-------#{stock.id}"
      (10.days.ago.to_date..Date.today).each do |date|
        puts "-------#{stock.id}, #{date.to_s(:db)}"
        key = intraday_key(stock.id, date)
        data_from_redis(key, stock.market_area, expired_at)
      end
      puts "Finish-------#{stock.id}"
    end
  end

  # 临时方法
  def self.intraday_key(stock_id, date)
    "stock_intraday_#{stock_id}_" + date.to_s(:db)
  end
  def self.data_from_redis(key, market, expired_at)
    data = $redis.hgetall(key)
    return if data.blank?
    data = data.sort.inject([]){|a, b| a << (Marshal.load(b[1]).merge({trade_time: transform_redis_time(b[0], market), local_date: transform_to_local_date(b[0], market), market: market, expired_at: expired_at}) rescue nil); a }
    import_to_mysql(data.first.keys, data.map(&:values))
  end

  def self.transform_redis_time(timestamp, market)
    market==:us ? Time.at(timestamp.to_i).to_s(:db).to_estime : Time.at(timestamp.to_i)
  end

  def self.transform_to_local_date(timestamp, market)
    transform_redis_time(timestamp, market).to_date
  end

end
