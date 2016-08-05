module Xignite
  module RealTime
    class Base
      URL = "http://globalquotes.xignite.com/v3/xGlobalQuotes.json/GetGlobalDelayedQuotes"

      attr_accessor :symbols

      def initialize(symbols)
        raise ArgumentError, "symbols must be an array" unless symbols.is_a?(Array)

        @symbols = symbols
      end

      def sync
        @response = Xignite::Base.get(request_url)
        
        realtime_stocks.each{|stock| stock.save_to_redis }
      end

      def realtime_stocks
        @response.body.map do |stock|
          
          if stock.fetch('Outcome').downcase == 'success'
            attrs = stock.deep_transform_keys!{|x| x.to_s.underscore }
            Quote.new(attrs.merge('base_stock_id' => base_stock_ids.fetch( attrs['security']['symbol'] )))
          else
            $xignite_logger.error("rt_sync error!!! " + stock['Security']['Symbol'] + ',' + stock['Message'])
            
            next 
          end

        end.compact
      rescue Exception => e
        $xignite_logger.error("rt parse response body err!!!" + e.message)
        []
      end

      def request_url
        URL + "?IdentifierType=Symbol&Identifiers=#{@symbols.join(',')}&_token=#{Setting.xignite.token}"
      end

      def base_stock_ids
        @base_ids || (@base_ids = BaseStock.where(xignite_symbol: @symbols).map{|x| [x.xignite_symbol, x.id] }.to_h)
      end
    end

    class Quote
      
      FIELDS = %w(symbol previous_close last change_from_previous_close percent_change_from_previous_close currency volume high52_weeks low52_weeks open high low ask bid date time utc_offset base_stock_id)
      
      def initialize(opts = {})
        FIELDS.each do |attribute|
          instance_variable_set("@#{attribute}", opts[attribute] || opts['security'][attribute])
        end
      end

      def market
        @symbol =~ /\.XHKG$/ ? :hk : :us
      end
      
      def local_date
        Date.strptime(@date, "%m/%d/%Y")
      rescue
        nil
      end

      def trade_time
        ActiveSupport::TimeZone[@utc_offset].parse(trade_time_without_zone).to_time
      rescue Exception => e
        $xignite_logger.error("#{@symbol} trade time parse error!!! " + e.message)

        nil
      end

      def trade_time_without_zone
        Time.strptime([@date, @time].join(' '), "%m/%d/%Y %I:%M:%S %p").to_s(:db)
      end
      
      def to_hash
        instance_values.merge(market: market, trade_time: trade_time, local_date: local_date).symbolize_keys.except(:date, :time, :utc_offset)
      end
      
      # 保存到REDIS中
      def save_to_redis
        Redis.current.mapped_hmset(snapshot_key, self.to_hash)
      end

      def snapshot_key
        "realtime:" + @base_stock_id.to_s
      end
    end
  end
end
