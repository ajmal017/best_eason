module Yahoo
  module StockIndex
    class Base

      def self.sync
        stocks = StockQuote::Stock.json_quote(Stock::SYMBOLS.keys, nil, nil, Stock::FIELDS.values)['quote']
        stocks = [stocks] if stocks.is_a?(Hash)
        stocks.each { |attrs| Stock.new(attrs).store }
        ::StockIndex.notify
      end

    end

    class Stock
      
      attr_accessor :symbol, :index, :change, :percent

      FIELDS = {symbol: 'Symbol', index: 'LastTradePriceOnly', change: 'Change', percent: 'ChangeinPercent' }
      
      SYMBOLS = {'^ixic' => 'stock_index_nasdq', '^gspc' => 'stock_index_bp', '^hsi' => 'stock_index_hs' }

      def initialize(opts = {})
        FIELDS.map { |k, v| self.send("#{k}=", opts[v]) }
      end
      
      def percent=(value)
        @percent = value.gsub(/\+|%/, '')
      end

      def change=(value)
        @change = Caishuo::Utils::Helper.pretty_number(value).gsub(/\+/, '')
      end

      def index=(value)
        @index = Caishuo::Utils::Helper.pretty_number(value)
      end

      def redis_key
        SYMBOLS[@symbol.downcase]
      end

      def store
        $redis.mapped_hmset(redis_key, self.instance_values.reject{|k, v| k == 'symbol'})
      end

    end
  end
end
