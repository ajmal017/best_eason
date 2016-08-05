module Xignite
  module Strategy
    
    class Typhoeus

      URL = "http://www.xignite.com/xGlobalHistorical.json/GetGlobalHistoricalQuotesRange"

      def initialize(symbol)
        @symbol = symbol
      end

      def run
        start = Time.now.to_i

        response = Xignite::Base.get(request_url)

        $xignite_logger.info("#{@symbol} 执行时间 #{Time.now.to_i - start}")
        
        response.body['GlobalQuotes'].map do |stock|
          Xignite::Historical::Quote.new(stock.transform_keys!(&:underscore).merge('symbol' => @symbol, 'base_stock_id' => base_id, validate: true))
        end.sort_by{ |quote| quote.date }
      
      rescue Exception => e
        $xignite_logger.warn("#{@symbol} typhoeus error, #{e.message}")
        
        Xignite::Retry.new(base_id, @symbol).retry
        
        []
      end

      def request_url
        URL + "?IdentifierType=Symbol&Identifier=#{URI.encode(@symbol)}&AdjustmentMethod=SplitAndProportionalCashDividend&StartDate=#{start_date}&EndDate=#{end_date}&_token=#{Setting.xignite.token}"
      end

      def start_date
        date_str = Xignite::Historical::Quote.new('base_stock_id' => base_id).recent_date
        Date.parse(date_str).strftime('%m/%d/%Y')
      end

      def end_date
        Date.today.strftime('%m/%d/%Y')
      end

      def base_id
        @base_stock_id || ( @base_stock_id = BaseStock.find_by(xignite_symbol: @symbol).try(:id) )
      end

    end

  end
end
