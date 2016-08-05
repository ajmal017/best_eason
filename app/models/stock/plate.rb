module Stock
  class Plate < BaseStock
    cattr_accessor :screenshot_key, instance_writer: false, instance_reader: false

    has_one :plate, class_name: "Plate::Base", foreign_key: :base_stock_id

    def self.exchange
      @@exchange||=Exchange::Cn.instance
    end

    def self.exchange=(exchange)
      @@exchange = exchange
    end

    def historical_quote_class
      ::HistoricalQuoteCn
    end

    def can_trade?
      false
    end

    def market_capitalization
      realtime_infos[:market_capitalization].to_i
    end

    def can_add_to_realtime_queue?
      false
    end

    def is_index?
      true
    end

    def top_stocks_by_exchange(order = "desc", limit = 10)
      $cache.fetch("cs:top_stocks:plates:#{id}:#{order}", expires_in: 1.minutes) do
        plate.base_stocks.select(:id, :name, :c_name)
        .includes(:stock_screener).joins(:stock_screener)
        .where("stock_screeners.change_rate is not null and stock_screeners.change_rate > -100")
        .order("stock_screeners.change_rate #{order}").limit(limit)
      end
    end

    def market_name
      "行业指数"
    end

    def market_area
      plate.market.to_sym
    end

    # 最后交易时间
    def trade_time
      Time.parse($redis.hget(snapshot_key, "trade_time")) rescue nil
    end

    # 交易日期
    def trading_date
      trade_time.to_date rescue nil
    end

    # 振幅
    def amplitude
      nil
    end

    # 成交额
    def turnover
      nil
    end

  end
end
