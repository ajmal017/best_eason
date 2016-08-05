module Yahoo
  module Currency
    class Base
      attr_accessor :response

      def sync
        @response = Remote::Base.get(request_url)
        rates.each{|r| r.redis_save }
      end

      def rates
        json_results = $json.decode @response.body
        currencies = json_results['query']['results']['quote']
        
        currencies.map do |c|
          Rate.new(c.transform_keys!{|x| x.to_s.underscore })
        end
      rescue 
        []
      end

      def request_url
        url = "http://query.yahooapis.com/v1/public/yql?q="
        url += URI.encode("SELECT #{ select_fields } FROM yahoo.finance.quotes WHERE symbol IN (#{to_p(Rate::SYMBOLS.keys)})")
        url += "&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
      end

      def select_fields
        Rate::FIELDS.map { |field| field.classify }.join(',')
      end

      def to_p(symbols)
        "'" + symbols.join("','").gsub(" ", "").upcase + "'"
      end

    end

    class Rate
      FIELDS = %w(last_trade_date last_trade_price_only symbol last_trade_time)

      SYMBOLS = {
        "HKD=X" => "usd_to_hkd", "CNY=X" => "usd_to_cny", "HKDUSD=X" => "hkd_to_usd", "CNYUSD=X" => "cny_to_usd", "HKDCNY=X" => "hkd_to_cny", "CNYHKD=X" => "cny_to_hkd"
      }
      
      def initialize(opts = {})
        FIELDS.each do |attribute|
          instance_variable_set("@#{attribute}", opts[attribute])
        end
      end
      
      def redis_save
        $redis.mapped_hmset(currency_key, instance_values)
      end

      def currency_key
        "currency:#{SYMBOLS[@symbol]}" 
      end

    end
  end
end
