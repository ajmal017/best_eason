module Yahoo
  module Strategy
    class Yql
      attr_accessor :stock, :historicals

      def initialize(stock)
        @stock = stock
        @historicals = []
      end

      def run
        results
      end

      def retrieve_historicals
        (@stock.recent_date.to_date..Date.today).step(300) do |start_date|
          end_date = [start_date + 300.pred, Date.today].min
          quotes, succ = Remote::Tools::Historical.sync(stock.symbol, start_date, end_date, false)
          break stock.retry unless succ
          quotes = quotes.reverse if quotes.is_a?(Array)
          historicals << quotes
        end
        historicals
      end

      def results
        rets = retrieve_historicals.flatten.map! do |quote|
          attrs = quote.transform_keys!{|x| x.underscore }.merge!(base_id: @stock.base_id).symbolize_keys!
          Yahoo::Historical::Stock.new(attrs.merge(validate: true))
        end
        { @stock => rets }
      rescue YahooFinanceException
        {}
      end

    end
  end
end
