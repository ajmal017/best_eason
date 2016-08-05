module Yahoo
  class HistoricalChange
    NUM_PER_MONITOR = 200

    attr_accessor :start_id

    def initialize(start_id, sign)
      @start_id = start_id
      @end_id = @start_id + NUM_PER_MONITOR.pred
      @sign = sign
      @symbols = BaseStock.between(@start_id, @end_id)
    end

    def monitor
      stocks, status = Remote::Tools::Historical.sync(@symbols, 1.days.ago, Date.today)
      stocks.each do |stock|
        if Date.parse(stock['Date']) >= Date.yesterday
          qc = QuoteChange.find_or_create_by(symbol: stock['Symbol'], date: stock['Date'])
          qc.update(sign: @sign) if qc.sign.nil?
          qc.update(adj_close: stock['Adj_Close'].to_d)
        end
      end
    end

  end
end

