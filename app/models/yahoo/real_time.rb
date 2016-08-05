module Yahoo
  module RealTime
    class Base
      # 每次实时同步数量
      NUM_PER_SYNC = 300

      attr_accessor :symbols, :response, :stocks

      def initialize(symbols)
        @symbols = symbols
      end

      def ticker_base_ids(tickers)
        Hash[BaseStock.where(ticker: tickers).map{ |x| [x.ticker, x.id] }]
      end

    end

    class YQL < Base

      FIELDS = %w(Symbol LastTradePriceOnly MarketCapitalization PreviousClose AverageDailyVolume ChangeinPercent PERatio Currency LastTradeTime LastTradeDate Volume YearLow YearHigh Open DaysHigh DaysLow Ask Bid Change)

      def initialize(symbols)
        super(symbols)
        @stocks = []
      end

      def sync
        begin
          start_at = Time.now
          @stocks = StockQuote::Stock.json_quote(symbols, nil, nil, FIELDS)['quote']
          @stocks = [@stocks] if @stocks.is_a?(Hash)
          $rt_logger.info("YQL抓取时间: #{Time.now - start_at}, first_symbol: #{@symbols.first}, stocks_count: #{@stocks.count}")
        rescue Exception => e 
          $rt_logger.error("YQL出错了!!! message: #{e.message}, backtrace: #{e.backtrace.join('\n')}")
        end
        Yahoo::RealTime::Stock.save_to_mysql(realtime_stocks)
        
        realtime_stocks.each{|stock| stock.redis_save }
        
        sync_missing_symbols if has_lost?
      end


      def has_lost?
        @stocks.present? && @stocks.count != @symbols.count
      end

      def sync_missing_symbols
        missing_symbols = @symbols - @stocks.map{|x| x[:symbol]}
        Download.new(missing_symbols).sync if missing_symbols.present?
      end

      def realtime_stocks
        base_ids = ticker_base_ids(@symbols)
        rets = @stocks.map do |stock|
          attrs = stock.transform_keys!{|x| x.to_s.underscore }.symbolize_keys!
          Yahoo::RealTime::Stock.new(attrs.merge(base_id: base_ids.fetch(attrs[:symbol], nil))) 
        end
      end

    end

    class Download < Base
      BASE_URL = "http://download.finance.yahoo.com/d/quotes.csv?"

      FIELDS = {
        's' => 'symbol',
        'p' => 'previous_close',
        'j1' => 'market_capitalization',
        'a2' => 'average_daily_volume',
        'r5' => 'pe_ratio',
        'l1' => 'last_trade_price_only',
        'p2' => 'changein_percent',
        'c1' => 'change',
        'c4' => 'currency',
        't1' => 'last_trade_time',
        'd1' => 'last_trade_date',
        'v'  => 'volume'
      }

      def sync
        @response = Remote::Tools::RealTime.get(request_url)
        Yahoo::RealTime::Stock.save_to_mysql(stocks)
        stocks.each{|stock| stock.redis_save }
      rescue Exception => e
        $rt_logger.error("Download出错了!!! message: #{e.message}, backtrace: #{e.backtrace.join('\n')}")
        Yahoo::RtLog.create(message: @symbols.join(',').truncate(255)) 
      end

      def request_url
        BASE_URL + "f=#{FIELDS.keys.join}&s=#{URI.encode(@symbols.join(','))}"
      end

      def stocks
        base_ids = ticker_base_ids(@symbols)
        rets = CSV.parse(@response.body, :converters => :all, :headers => FIELDS.values).map do |x|
          attrs = x.to_hash.symbolize_keys!
          Yahoo::RealTime::Stock.new(attrs.merge(base_id: base_ids.fetch(attrs[:symbol], nil)))        
        end
      end



    end

    class Stock
      attr_accessor :base_id, :symbol, :previous_close, :market_capitalization, :average_daily_volume, :pe_ratio, :last_trade_price_only, :changein_percent, :currency, :last_trade_time, :last_trade_date, :volume, :year_low, :year_high, :open, :days_high, :days_low, :ask, :bid, :change

      def initialize(opts = {})
        %w(base_id symbol previous_close market_capitalization average_daily_volume pe_ratio last_trade_price_only changein_percent currency last_trade_time last_trade_date volume year_low year_high open days_high days_low ask bid change).each do |attribute|
          instance_variable_set("@#{attribute}", opts[attribute.to_sym])
        end
      end

      # 作废
      def snapshot_key
        "stock_real_time_#{@base_id}"
      end
      
      # 暂时保存到REDIS中
      def redis_save
        Redis.current.mapped_hmset(snapshot_key, instance_values)
      end

      # 作废
      def store
        Redis.current.mapped_hmset(snapshot_key, instance_values)
        
        # 记录分时图记录
        intraday_store

        # 冗余最后实时价格
        store_stock_close_price
      end

      # 作废
      def store_stock_close_price
        infos = instance_values.symbolize_keys.slice(:last_trade_price_only, :changein_percent, :change, :previous_close)
        
        $cache.multi_hwrite(stock_price_key, { @base_id => infos })
      end

      # 作废
      # 记录股票当天最后实时价格作为后补ADJ_CLOSE 
      def stock_price_key
        "stock_close_price: #{trade_date.to_s(:db)}"
      end

      # 作废
      def intraday_key
        "stock_intraday_#{@base_id}_#{trade_date.to_s(:db)}"
      end

      # 作废
      def intraday_store
        infos = instance_values.symbolize_keys.slice(:base_id, :symbol, :last_trade_price_only, :volume)
        
        #unless $redis.hexists(intraday_key, format_trade_time)
        $cache.multi_hwrite(intraday_key, { format_trade_time => infos }) and set_expire
        #end
      end

      # 作废
      def set_expire
        $redis.expire(intraday_key, 8.days)
      end

      # 作废
      def format_trade_time
        return Time.parse(trade_time).to_i unless sehk?
        trade_time.in_time_zone('Eastern Time (US & Canada)').in_time_zone('Beijing').to_i
      rescue 
        0
      end

      # used
      def trade_date
        Date.strptime(last_trade_date, "%m/%d/%Y") rescue 0
      end

      def trade_time
        trade_time = Time.strptime([last_trade_date, last_trade_time, "-05"].join(' '), "%m/%d/%Y %I:%M%p %Z")
        (sehk? && trade_at_afternoon?) ? trade_time.yesterday.to_s(:db) : trade_time.to_s(:db)
      end

      def trade_at_afternoon?
        last_trade_time =~ /pm$/
      end

      def us_dst?(time)
        time.in_time_zone('Eastern Time (US & Canada)').dst?
      end

      def sehk?
        symbol =~ /\.HK$/
      end

      def market
        sehk? ? :hk : :us
      end

      STORE_KEYS = %w{base_id symbol volume last_trade_price_only changein_percent change previous_close}
      def to_hash(expired_at=nil)
        instance_values.slice(*STORE_KEYS).merge({market: market, trade_time: trade_time, local_date: trade_date, expired_at: expired_at || 10.days.since.to_date})
      end

      def self.transform_data(data)
        return [nil, nil] if data.blank?
        expired_at = IntradayQuote::EXPIRED_DAYS.since.to_date
        data = data.map{|s| s.to_hash(expired_at) rescue nil}.compact
        return data[0].keys, data.map(&:values)
      end

      def self.save_to_mysql(stocks=[])
        keys, values = transform_data(stocks)
        IntradayQuote.import_to_mysql(keys, values, ignore: true)
      end

    end

  end
end
