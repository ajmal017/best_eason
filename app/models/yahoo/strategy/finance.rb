module Yahoo
  module Strategy
    class Finance
      attr_accessor :stock

      def initialize(stock)
        @stock = stock
      end

      def run
        results
      end

      def results
        rets = historicals.collect do |quote|
          attrs = quote.instance_values.transform_keys!{|x| x.underscore }.merge!(base_id: @stock.base_id).symbolize_keys!
          Yahoo::Historical::Stock.new(attrs.merge(validate: true))
        end
        { @stock => rets }
      rescue YahooFinanceException
        {}
      end

      def historicals
        
        $finance_logger.info("FinanceSyncing... #{@stock.symbol} #{@stock.recent_date}")
        
        quotes = YahooFinance.get_HistoricalQuotes(@stock.symbol, Date.parse(@stock.recent_date), Date.today).reverse
        @stock.retry if quotes.blank?
        quotes
      rescue Exception => e
        $finance_logger.error(@stock.symbol + " Finance出错了 " + e.message)
        @stock.retry
        []
      end

    end
  end
end
