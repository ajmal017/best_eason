module Yahoo
  module Strategy
    class Typhoeus
      attr_accessor :hydra, :results

      def initialize(stocks, concurrent_connections = 20, memoize_requests = false)
        @hydra = ::Typhoeus::Hydra.new(max_concurrency: concurrent_connections)
        @hydra.disable_memoization unless memoize_requests
        @results = {}
        add_queues_for(stocks)
      end

      def run
        @hydra.run
        results
      end

      def add_queues_for(stocks)
        stocks.each{ |quote| @hydra.queue(build_request(quote)) }
      end

      private 

      def build_request(quote)
        request = ::Typhoeus::Request.new(
          quote.request_url, 
          :headers => {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1", "Referer"=>"http://www.baidu.com"}, 
          :timeout => 30000 ,
          proxy: Setting.proxy.url
        )
        request.on_complete do |response| 
          $finance_logger.info([quote.symbol, response.time].join('同步时间'))
          if response.success?
            historical_stocks = parse_response(quote, response.body)
            results.merge!(quote => historical_stocks.reverse) if historical_stocks
          else
            quote.retry
          end
        end
        request
      end

      def parse_response(stock, body)
        rets = Array.new.tap do |ret|
          CSV.parse(body, :converters => :all, :headers => [:date, :open, :high, :low, :close, :volume, :adj_close]).each_with_index do |line, index|
            next if index.zero?
            attrs = line.to_hash.merge(base_id: stock.base_id, symbol: stock.symbol, validate: true)
            ret << Yahoo::Historical::Stock.new(attrs)
          end
        end
      rescue Exception => e
        nil
      end

    end
  end
end
