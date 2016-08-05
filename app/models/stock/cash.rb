class Stock::Cash

  class << self
    def id
      0
    end

    def symbol
      "cash.cash"
    end

    def stock_index
      1000
    end

    def stock_return
      0
    end

    # cash任何时间的index均无变化
    def indices_by(start_date, end_date)
      indices_by_dates((start_date..end_date).to_a)
    end

    def indices_by_dates(dates)
      dates.map{|d| [d.to_s(:db), stock_index]}.to_h
    end

    def id_weights_with(weights)
      weights.merge(Stock::Cash.id => weight_with(weights))
    end

    def weight_with(weights)
      BigDecimal.new(1) - (weights.values.reduce(:+) || 0)
    end

    def symbol_weights_with(weights)
      cash_weight = BigDecimal.new(1) - (weights.values.reduce(:+) || 0)
      weights.merge(Stock::Cash.symbol => cash_weight)
    end

  end
  
end