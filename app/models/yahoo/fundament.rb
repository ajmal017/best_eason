module Yahoo
  module Fundament
    class Base
      attr_accessor :symbols, :response

      def initialize(symbols)
        raise ArgumentError, "symbols must be an array" unless symbols.is_a?(Array)

        @symbols = symbols
      end

      def sync
        @response = Remote::Base.get(request_url)
        
        realtime_quotes.each {|quote| quote.redis_save }
      end

      def realtime_quotes
        json_results = $json.decode @response.body
        quotes = json_results['query']['results']['quote']

        quotes.map do |quote|
          attrs = quote.transform_keys!{|x| x.to_s.underscore }
          Quote.new(attrs.merge('base_stock_id' => base_stock_ids.fetch(attrs['symbol'], nil)))
        end
      rescue 
        []
      end

      def request_url
        url = "http://query.yahooapis.com/v1/public/yql?q="
        url += URI.encode("SELECT #{ select_fields } FROM yahoo.finance.quotes WHERE symbol IN (#{to_p( @symbols )})")
        url += "&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
      end

      def select_fields
        (Quote::FIELDS - except_fields).map{|field| field.classify }.push('PERatio').join(',')
      end

      def except_fields
        %w(base_stock_id pe_ratio)
      end

      def to_p(symbols)
        "'" + symbols.join("','").gsub(" ", "").upcase + "'"
      end

      def base_stock_ids
        @base_stock_ids || ( @base_stock_ids = BaseStock.where(ticker: @symbols).map{|bs| [bs.ticker, bs.id] }.to_h )
      end

    end

    class Quote
      FIELDS = %w(market_capitalization average_daily_volume pe_ratio base_stock_id symbol)

      def initialize(opts = {})
        FIELDS.each do |attribute|
          instance_variable_set("@#{attribute}", opts[attribute])
        end
      end

      def redis_save
        $redis.mapped_hmset(snapshot_key, to_hash)
      end

      def to_hash
        instance_values.except('symbol', 'base_stock_id')
      end

      def snapshot_key
        "realtime:" + @base_stock_id.to_s
      end
    end
  end
end
